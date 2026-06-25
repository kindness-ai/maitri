if maitri-battery-present; then
  powerprofilesctl set balanced || true

  # Enable battery monitoring timer for low battery notifications
  systemctl --user enable --now maitri-battery-monitor.timer
else
  powerprofilesctl set performance || true
fi
