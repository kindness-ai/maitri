# Make fish the default login shell (maitri default). The bash configs stay in
# place, and maitri ships ~/.config/fish/config.fish with the maitri environment.
if command -v fish &>/dev/null; then
  fish_path="$(command -v fish)"
  grep -qxF "$fish_path" /etc/shells || echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
  if [[ ${SHELL:-} != "$fish_path" ]]; then
    sudo chsh -s "$fish_path" "$USER" || true
  fi
fi
