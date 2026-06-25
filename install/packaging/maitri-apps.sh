# maitri default desktop apps from the [maitri] package channel (prebuilt + signed).
# These need network at install time and are NOT bundled in the offline ISO mirror.
# Tolerant: a single package failing won't abort the whole install.

maitri_apps=(
  walker                 # app launcher
  elephant-all           # walker data providers
  visual-studio-code-bin # editor (maitri default)
  sublime-text-4         # editor
  warp-terminal-bin      # terminal
  helium-browser-bin     # browser (maitri default)
  hyprmon-bin            # Hyprland monitor manager (TUI)
)

for pkg in "${maitri_apps[@]}"; do
  maitri-pkg-add "$pkg" || echo -e "\e[33mmaitri: skipped '$pkg' (no network — install later with: maitri-pkg-add $pkg)\e[0m"
done
