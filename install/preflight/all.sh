source $MAITRI_INSTALL/preflight/guard.sh
source $MAITRI_INSTALL/preflight/begin.sh
run_logged $MAITRI_INSTALL/preflight/show-env.sh
run_logged $MAITRI_INSTALL/preflight/pacman.sh
run_logged $MAITRI_INSTALL/preflight/migrations.sh
run_logged $MAITRI_INSTALL/preflight/first-run-mode.sh
run_logged $MAITRI_INSTALL/preflight/disable-mkinitcpio.sh
