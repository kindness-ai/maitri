# Overwrite parts of the maitri-menu with user-specific submenus.
# See $MAITRI_PATH/bin/maitri-menu for functions that can be overwritten.
#
# WARNING: Overwritten functions will obviously not be updated when maitri changes.
#
# Example of minimal system menu:
#
# show_system_menu() {
#   case $(menu "System" "  Lock\n󰐥  Shutdown") in
#   *Lock*) maitri-system-lock ;;
#   *Shutdown*) maitri-system-shutdown ;;
#   *) back_to show_main_menu ;;
#   esac
# }
#
# Example of overriding just the about menu action: (Using zsh instead of bash (default))
#
# show_about() {
#   exec maitri-launch-or-focus-tui "zsh -c 'fastfetch; read -k 1'"
# }
