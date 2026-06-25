# Set default XCompose that is triggered with CapsLock
mkdir -p ~/.config/X11
tee ~/.config/X11/Xcompose >/dev/null <<EOF
# Run maitri-restart-xcompose to apply changes

# Include fast emoji access
include "%H/.local/share/maitri/default/xcompose"

# Identification
<Multi_key> <space> <n> : "$MAITRI_USER_NAME"
<Multi_key> <space> <e> : "$MAITRI_USER_EMAIL"
EOF
