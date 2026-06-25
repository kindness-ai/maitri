#!/usr/bin/env bash
set -euo pipefail

use_maitri_helpers() {
  export MAITRI_PATH="/root/maitri"
  export MAITRI_INSTALL="/root/maitri/install"
  export MAITRI_INSTALL_LOG_FILE="/var/log/maitri-install.log"
  export MAITRI_MIRROR="$(cat /root/maitri_mirror)"
  source /root/maitri/install/helpers/all.sh
}

run_configurator() {
  set_spark_colors
  ./configurator
  export MAITRI_USER="$(jq -r '.users[0].username' user_credentials.json)"
}

install_arch() {
  clear_logo
  gum style --foreground 3 --padding "1 0 0 $PADDING_LEFT" "Installing..."
  echo

  touch /var/log/maitri-install.log

  start_log_output

  # Set CURRENT_SCRIPT for the trap to display better when nothing is returned for some reason
  CURRENT_SCRIPT="install_base_system"
  install_base_system > >(sed -u 's/\x1b\[[0-9;]*[a-zA-Z]//g' >>/var/log/maitri-install.log) 2>&1
  unset CURRENT_SCRIPT
  stop_log_output
}

install_maitri() {
  chroot_bash -lc "sudo pacman -S --noconfirm --needed gum" >/dev/null
  chroot_bash -lc "source /home/$MAITRI_USER/.local/share/maitri/install.sh || bash"

  configure_login_for_unencrypted_install

  # Reboot if requested by installer
  if [[ -f /mnt/var/tmp/maitri-install-completed ]]; then
    reboot
  fi
}

# Set maitri Spark color scheme for the terminal
set_spark_colors() {
  if [[ $(tty) == "/dev/tty"* ]]; then
    # maitri Spark color palette
    echo -en "\e]P00b0f17" # black (background)
    echo -en "\e]P1ff6e6e" # red
    echo -en "\e]P27de38b" # green
    echo -en "\e]P3ffd479" # yellow
    echo -en "\e]P482aaff" # blue
    echo -en "\e]P5c99bff" # magenta
    echo -en "\e]P66fe6d9" # cyan
    echo -en "\e]P7b8bed0" # white
    echo -en "\e]P82c3548" # bright black
    echo -en "\e]P9ff8b8b" # bright red
    echo -en "\e]PA9ceba6" # bright green
    echo -en "\e]PBffe099" # bright yellow
    echo -en "\e]PCa0c0ff" # bright blue
    echo -en "\e]PDdbb6ff" # bright magenta
    echo -en "\e]PE97f0e6" # bright cyan
    echo -en "\e]PFe6e9f0" # bright white (foreground)

    # Set default foreground and background
    echo -en "\033[0m"
    clear
  fi
}

install_disk() {
  jq -er 'first(.disk_config.device_modifications[]? | select(.wipe == true) | .device)' user_configuration.json
}

cleanup_install_disk() {
  local disk="$1"

  if [[ -z "$disk" || ! -b "$disk" ]]; then
    echo "Could not determine install disk for cleanup" >&2
    return 1
  fi

  echo "Cleaning up existing holders on install disk: $disk"

  # Ensure that no mounts exist from past install attempts.
  findmnt -R /mnt >/dev/null && umount -R /mnt || true

  # Turn off swap and unmount anything backed by the selected disk, including
  # device-mapper children from a previous install. Active LVM/swap holders can
  # prevent the kernel from re-reading the partition table after archinstall
  # wipes and recreates it.
  while read -r dev; do
    [[ -b "$dev" ]] || continue

    swapoff "$dev" 2>/dev/null || true

    while read -r target; do
      [[ -n "$target" ]] || continue
      umount "$target" 2>/dev/null || true
    done < <(findmnt -rn -S "$dev" -o TARGET 2>/dev/null || true)
  done < <(lsblk -rnpo PATH "$disk")

  # Deactivate any LVM volume groups whose physical volumes live on the selected
  # disk. This is the common case when replacing Fedora/Alma/RHEL installs.
  while read -r dev type; do
    [[ "$type" == "disk" || "$type" == "part" || "$type" == "crypt" ]] || continue

    while read -r vg; do
      [[ -n "$vg" ]] || continue
      vgchange -an "$vg" 2>/dev/null || true
    done < <(pvs --noheadings -o vg_name "$dev" 2>/dev/null | awk '{$1=$1; print}' | sort -u)
  done < <(lsblk -rnpo PATH,TYPE "$disk")

  # Close any LUKS mappings stacked on the selected disk after filesystems and
  # swap have been released.
  while read -r dev type; do
    [[ "$type" == "crypt" ]] || continue
    cryptsetup close "$dev" 2>/dev/null || true
  done < <(lsblk -rnpo PATH,TYPE "$disk")

  blockdev --flushbufs "$disk" 2>/dev/null || true
  partprobe "$disk" 2>/dev/null || true
  udevadm settle || true
}

install_base_system() {
  # Initialize and populate the keyring
  pacman-key --init
  pacman-key --populate archlinux
  pacman-key --populate maitri

  # Sync the offline database so pacman can find packages
  pacman -Sy --noconfirm

  cleanup_install_disk "$(install_disk)"

  # Workarounds for archinstall 4.2 regressions under Python 3.14:
  # 1. sync_log_to_install_medium: `self.target / absolute_logfile` drops
  #    self.target because the RHS is absolute, so Path.copy() raises EINVAL
  #    (source == target).
  # 2. _add_limine_bootloader: `Path.copy(efi_dir_path)` raises IsADirectoryError
  #    because 3.14's Path.copy treats target as a literal path, not a directory
  #    (shutil.copy used to auto-append the source filename).
  sed -i \
    -e 's|logfile_target = self\.target / absolute_logfile$|logfile_target = self.target / absolute_logfile.relative_to("/")|' \
    -e 's|(limine_path / file)\.copy(efi_dir_path)|(limine_path / file).copy(efi_dir_path / file)|' \
    -e "s|(limine_path / 'limine-bios.sys')\.copy(boot_limine_path)|(limine_path / 'limine-bios.sys').copy(boot_limine_path / 'limine-bios.sys')|" \
    /usr/lib/python3.14/site-packages/archinstall/lib/installer.py

  # Install using files generated by the ./configurator
  # Skip NTP and WKD sync since we're offline (keyring is pre-populated in ISO)
  archinstall \
    --config user_configuration.json \
    --creds user_credentials.json \
    --silent \
    --skip-ntp \
    --skip-wkd \
    --skip-wifi-check

  # After archinstall sets up the base system but before our installer runs,
  # we need to ensure the offline pacman.conf is in place
  cp /etc/pacman.conf /mnt/etc/pacman.conf

  # Mount the offline mirror so it's accessible in the chroot
  mkdir -p /mnt/var/cache/maitri/mirror/offline
  mount --bind /var/cache/maitri/mirror/offline /mnt/var/cache/maitri/mirror/offline

  # Mount the packages dir so it's accessible in the chroot
  mkdir -p /mnt/opt/packages
  mount --bind /opt/packages /mnt/opt/packages

  # No need to ask for sudo during the installation (maitri itself responsible for removing after install)
  mkdir -p /mnt/etc/sudoers.d
  cat >/mnt/etc/sudoers.d/99-maitri-installer <<EOF
root ALL=(ALL:ALL) NOPASSWD: ALL
%wheel ALL=(ALL:ALL) NOPASSWD: ALL
$MAITRI_USER ALL=(ALL:ALL) NOPASSWD: ALL
EOF
  chmod 440 /mnt/etc/sudoers.d/99-maitri-installer

  # Copy the local maitri repo to the user's home directory
  mkdir -p /mnt/home/$MAITRI_USER/.local/share/
  cp -r /root/maitri /mnt/home/$MAITRI_USER/.local/share/

  chown -R 1000:1000 /mnt/home/$MAITRI_USER/.local/

  # Ensure all necessary scripts are executable
  find /mnt/home/$MAITRI_USER/.local/share/maitri -type f -path "*/bin/*" -exec chmod +x {} \;
  chmod +x /mnt/home/$MAITRI_USER/.local/share/maitri/boot.sh 2>/dev/null || true
  find /mnt/home/$MAITRI_USER/.local/share/maitri/default/waybar -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
}

configure_login_for_unencrypted_install() {
  if [[ $(<user_encrypt_installation.txt) != "false" ]]; then
    return
  fi

  # Unencrypted installs must stop at SDDM so the user password is entered
  # before reaching the desktop. maitri's normal encrypted path may autologin
  # because the disk password was already entered at boot.
  #
  # Keep the maitri SDDM theme and seed SDDM's last user/session state so
  # first boot looks like the SDDM screen shown after logging out of maitri.
  mkdir -p /mnt/etc/sddm.conf.d
  rm -f /mnt/etc/sddm.conf.d/autologin.conf
  cat >/mnt/etc/sddm.conf.d/99-maitri-login.conf <<EOF
[Theme]
Current=maitri

[Users]
RememberLastUser=true
RememberLastSession=true
EOF

  mkdir -p /mnt/var/lib/sddm
  cat >/mnt/var/lib/sddm/state.conf <<EOF
[Last]
Session=maitri.desktop
User=$MAITRI_USER
EOF

  rm -f /mnt/etc/systemd/system/getty@tty1.service.d/autologin.conf
  arch-chroot /mnt chown sddm:sddm /var/lib/sddm /var/lib/sddm/state.conf >/dev/null 2>&1 || true
  arch-chroot /mnt systemctl enable sddm.service >/dev/null 2>&1 || true
}

chroot_bash() {
  HOME=/home/$MAITRI_USER \
    arch-chroot -u $MAITRI_USER /mnt/ \
    env MAITRI_CHROOT_INSTALL=1 \
    MAITRI_USER_NAME="$(<user_full_name.txt)" \
    MAITRI_USER_EMAIL="$(<user_email_address.txt)" \
    MAITRI_MIRROR="$MAITRI_MIRROR" \
    USER="$MAITRI_USER" \
    HOME="/home/$MAITRI_USER" \
    /bin/bash "$@"
}

if [[ $(tty) == "/dev/tty1" ]]; then
  use_maitri_helpers
  run_configurator
  install_arch
  install_maitri
fi
