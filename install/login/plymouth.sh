if [[ $(plymouth-set-default-theme) != "maitri" ]]; then
  sudo cp -r "$HOME/.local/share/maitri/default/plymouth" /usr/share/plymouth/themes/maitri/
  sudo plymouth-set-default-theme maitri
fi
