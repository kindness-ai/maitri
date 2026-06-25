#!/bin/bash

set -e

# Set install mode to online since boot.sh is used for curl installations
export MAITRI_ONLINE_INSTALL=true

ansi_art='███╗   ███╗   █████╗   ██╗  ████████╗  ██████╗   ██╗
████╗ ████║  ██╔══██╗  ██║  ╚══██╔══╝  ██╔══██╗  ██║
██╔████╔██║  ███████║  ██║     ██║     ██████╔╝  ██║
██║╚██╔╝██║  ██╔══██║  ██║     ██║     ██╔══██╗  ██║
██║ ╚═╝ ██║  ██║  ██║  ██║     ██║     ██║  ██║  ██║
╚═╝     ╚═╝  ╚═╝  ╚═╝  ╚═╝     ╚═╝     ╚═╝  ╚═╝  ╚═╝
              loving-kindness, compiled'

clear
echo -e "\n$ansi_art\n"

# Use custom branch if instructed, otherwise default to main
MAITRI_REF="${MAITRI_REF:-main}"

# Set mirror based on branch
if [[ $MAITRI_REF == "dev" ]]; then
  export MAITRI_MIRROR=edge
  echo 'Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch' | sudo tee /etc/pacman.d/mirrorlist >/dev/null
elif [[ $MAITRI_REF == "rc" ]]; then
  export MAITRI_MIRROR=rc
  echo 'Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch' | sudo tee /etc/pacman.d/mirrorlist >/dev/null
else
  export MAITRI_MIRROR=stable
  echo 'Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch' | sudo tee /etc/pacman.d/mirrorlist >/dev/null
fi

sudo pacman -Syu --noconfirm --needed git

# Use custom repo if specified, otherwise default to maitri (kindness-ai/maitri)
MAITRI_REPO="${MAITRI_REPO:-kindness-ai/maitri}"

echo -e "\nCloning maitri from: https://github.com/${MAITRI_REPO}.git"
echo -e "\e[32mUsing branch: $MAITRI_REF\e[0m"
rm -rf ~/.local/share/maitri/
git clone --branch "$MAITRI_REF" "https://github.com/${MAITRI_REPO}.git" ~/.local/share/maitri >/dev/null

echo -e "\nInstallation starting..."
source ~/.local/share/maitri/install.sh
