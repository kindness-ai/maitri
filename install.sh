#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

# Define maitri locations
export MAITRI_PATH="$HOME/.local/share/maitri"
export MAITRI_INSTALL="$MAITRI_PATH/install"
export MAITRI_INSTALL_LOG_FILE="/var/log/maitri-install.log"
export PATH="$MAITRI_PATH/bin:$PATH"

# Install
source "$MAITRI_INSTALL/helpers/all.sh"
source "$MAITRI_INSTALL/preflight/all.sh"
source "$MAITRI_INSTALL/packaging/all.sh"
source "$MAITRI_INSTALL/config/all.sh"
source "$MAITRI_INSTALL/login/all.sh"
source "$MAITRI_INSTALL/post-install/all.sh"
