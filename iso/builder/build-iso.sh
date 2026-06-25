#!/bin/bash

set -e

# maitri defaults: pull the installer from the maitri repo (main branch) and ride
# the maitri stable package channel. Override via env when building variants.
MAITRI_INSTALLER_REPO="${MAITRI_INSTALLER_REPO:-kindness-ai/maitri}"
MAITRI_INSTALLER_REF="${MAITRI_INSTALLER_REF:-main}"
MAITRI_MIRROR="${MAITRI_MIRROR:-stable}"

# Note that these are packages installed to the Arch container used to build the ISO.
pacman-key --init
pacman --noconfirm -Sy archlinux-keyring
pacman --noconfirm -Sy archiso git sudo base-devel jq grub

# Pre-import the maitri signing key so pacman can verify packages without a keyserver lookup
pacman-key --add /builder/maitri.gpg
pacman-key --lsign-key "$(gpg --show-keys --with-colons /builder/maitri.gpg | awk -F: '/^fpr/{print $10; exit}')"

# Install maitri-keyring for package verification during build
pacman --config /configs/pacman-online-${MAITRI_MIRROR}.conf --noconfirm -Sy maitri-keyring
pacman-key --populate maitri

# Setup build locations
build_cache_dir="/var/cache"
offline_mirror_dir="$build_cache_dir/airootfs/var/cache/maitri/mirror/offline"
mkdir -p $build_cache_dir/
mkdir -p $offline_mirror_dir/

# We base our ISO on the official arch ISO (releng) config.
# maitri uses the releng profile shipped by the `archiso` package (installed above)
# instead of the archiso git submodule that upstream maitri-iso vendors.
cp -r /usr/share/archiso/configs/releng/* $build_cache_dir/
rm "$build_cache_dir/airootfs/etc/motd"

# Avoid using reflector for mirror identification as we are relying on the global CDN
rm -rf "$build_cache_dir/airootfs/etc/systemd/system/multi-user.target.wants/reflector.service"
rm -rf "$build_cache_dir/airootfs/etc/systemd/system/reflector.service.d"
rm -rf "$build_cache_dir/airootfs/etc/xdg/reflector"

# Bring in our configs
cp -r /configs/* $build_cache_dir/

# Persist MAITRI_MIRROR so it's available at install time
echo "$MAITRI_MIRROR" > "$build_cache_dir/airootfs/root/maitri_mirror"

# Setup maitri itself
if [[ -d /maitri ]]; then
  cp -rp /maitri "$build_cache_dir/airootfs/root/maitri"
else
  maitri_repo_dst="$build_cache_dir/airootfs/root/maitri"
  git clone -b $MAITRI_INSTALLER_REF https://github.com/$MAITRI_INSTALLER_REPO.git "$maitri_repo_dst"
fi

# Make log uploader available in the ISO too
mkdir -p "$build_cache_dir/airootfs/usr/local/bin/"

# Copy the maitri Plymouth theme to the ISO
mkdir -p "$build_cache_dir/airootfs/usr/share/plymouth/themes/maitri"
cp -r "$build_cache_dir/airootfs/root/maitri/default/plymouth/"* "$build_cache_dir/airootfs/usr/share/plymouth/themes/maitri/"

# Download and verify Node.js binary for offline installation
NODE_DIST_URL="https://nodejs.org/dist/latest"

# Get checksums and parse filename and SHA
NODE_SHASUMS=$(curl -fsSL "$NODE_DIST_URL/SHASUMS256.txt")
NODE_FILENAME=$(echo "$NODE_SHASUMS" | grep "linux-x64.tar.gz" | awk '{print $2}')
NODE_SHA=$(echo "$NODE_SHASUMS" | grep "linux-x64.tar.gz" | awk '{print $1}')

# Download the tarball
curl -fsSL "$NODE_DIST_URL/$NODE_FILENAME" -o "/tmp/$NODE_FILENAME"

# Verify SHA256 checksum
echo "$NODE_SHA /tmp/$NODE_FILENAME" | sha256sum -c - || {
    echo "ERROR: Node.js checksum verification failed!"
    exit 1
}

# Copy to ISO
mkdir -p "$build_cache_dir/airootfs/opt/packages/"
cp "/tmp/$NODE_FILENAME" "$build_cache_dir/airootfs/opt/packages/"

# Add our additional packages to packages.x86_64
arch_packages=(linux-t2 git gum jq openssl plymouth tzupdate maitri-keyring lvm2 cryptsetup parted)
printf '%s\n' "${arch_packages[@]}" >>"$build_cache_dir/packages.x86_64"

# Build list of all the packages needed for the offline mirror
all_packages=($(cat "$build_cache_dir/packages.x86_64"))
all_packages+=($(grep -v '^#' "$build_cache_dir/airootfs/root/maitri/install/maitri-base.packages" | grep -v '^$'))
all_packages+=($(grep -v '^#' "$build_cache_dir/airootfs/root/maitri/install/maitri-other.packages" | grep -v '^$'))
all_packages+=($(grep -v '^#' /builder/archinstall.packages | grep -v '^$'))

# Download all the packages to the offline mirror inside the ISO
mkdir -p /tmp/offlinedb
pacman --config /configs/pacman-online-${MAITRI_MIRROR}.conf --noconfirm -Syw "${all_packages[@]}" --cachedir $offline_mirror_dir/ --dbpath /tmp/offlinedb
repo-add --new "$offline_mirror_dir/offline.db.tar.gz" "$offline_mirror_dir/"*.pkg.tar.zst

# Create a symlink to the offline mirror instead of duplicating it.
# mkarchiso needs packages at /var/cache/maitri/mirror/offline in the container,
# but they're actually in $build_cache_dir/airootfs/var/cache/maitri/mirror/offline
mkdir -p /var/cache/maitri/mirror
ln -s "$offline_mirror_dir" "/var/cache/maitri/mirror/offline"

# Copy the offline pacman.conf to the ISO's /etc directory so the live environment uses our
# same config when booted. 
cp $build_cache_dir/pacman-offline.conf "$build_cache_dir/airootfs/etc/pacman.conf"

# Finally, we assemble the entire ISO
mkarchiso -v -w "$build_cache_dir/work/" -o "/out/" "$build_cache_dir/"

# Fix ownership of output files to match host user
if [ -n "$HOST_UID" ] && [ -n "$HOST_GID" ]; then
    chown -R "$HOST_UID:$HOST_GID" /out/
fi
