if [[ -n ${MAITRI_ONLINE_INSTALL:-} ]]; then
  # Install build tools
  maitri-pkg-add base-devel

  # Configure pacman
  sudo cp -f ~/.local/share/maitri/default/pacman/pacman-${MAITRI_MIRROR:-stable}.conf /etc/pacman.conf
  sudo cp -f ~/.local/share/maitri/default/pacman/mirrorlist-${MAITRI_MIRROR:-stable} /etc/pacman.d/mirrorlist

  sudo pacman-key --add ~/.local/share/maitri/iso/builder/maitri.gpg
  sudo pacman-key --lsign-key "$(gpg --show-keys --with-colons ~/.local/share/maitri/iso/builder/maitri.gpg | awk -F: '/^fpr/{print $10; exit}')"

  sudo pacman -Sy
  maitri-pkg-add maitri-keyring

  # Refresh all repos
  sudo pacman -Syyuu --noconfirm
fi
