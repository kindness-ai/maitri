# maitri default desktop apps. The list lives in install/maitri-apps.packages so it is a
# single source of truth — bundled into the offline ISO mirror (build-iso.sh) AND installed
# here, so an offline install still gets a working desktop. Tolerant: a single package
# failing won't abort the whole install.

mapfile -t maitri_apps < <(grep -v '^#' "$MAITRI_INSTALL/maitri-apps.packages" | grep -v '^$')

for pkg in "${maitri_apps[@]}"; do
  maitri-pkg-add "$pkg" || echo -e "\e[33mmaitri: skipped '$pkg' (install later with: maitri-pkg-add $pkg)\e[0m"
done
