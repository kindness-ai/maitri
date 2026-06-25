# Install all base packages
mapfile -t packages < <(grep -v '^#' "$MAITRI_INSTALL/maitri-base.packages" | grep -v '^$')
maitri-pkg-add "${packages[@]}"
