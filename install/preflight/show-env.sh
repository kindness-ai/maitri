# Show installation environment variables
gum log --level info "Installation Environment:"

env | grep -E "^(MAITRI_CHROOT_INSTALL|MAITRI_ONLINE_INSTALL|MAITRI_USER_NAME|MAITRI_USER_EMAIL|USER|HOME|MAITRI_REPO|MAITRI_REF|MAITRI_PATH)=" | sort | while IFS= read -r var; do
  gum log --level info "  $var"
done
