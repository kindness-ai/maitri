# maitri: install the 1Password beta extension by default in Chromium and Helium.
# "normal_installed" = present out of the box, but the user can still remove it.
# (Managed-policy mechanism — the supported way to preinstall a Web Store extension.)
#
# Helium (ungoogled-chromium) routes Web Store downloads through its services proxy
# (default services.helium.imput.net), so the policy-listed extension only finishes
# downloading once Helium services are consented to — helium-profiles.sh seeds that
# consent per profile. 1Password installs the native-messaging host automatically; we
# just add Helium to its allowed-browsers list.

ext_json='{ "ExtensionSettings": { "khgocmkkpikpnmmkgmdnfckapcdkgfaf": { "installation_mode": "normal_installed", "update_url": "https://clients2.google.com/service/update2/crx" } } }'

for browser in chromium helium; do
  policy_dir="/etc/$browser/policies/managed"
  sudo mkdir -p "$policy_dir"
  echo "$ext_json" | sudo tee "$policy_dir/extensions.json" >/dev/null
done

# Let the 1Password desktop app accept connections from Helium (a non-default browser).
allowed=/etc/1password/custom_allowed_browsers
sudo mkdir -p "$(dirname "$allowed")"
if ! sudo grep -qxF helium "$allowed" 2>/dev/null; then
  echo helium | sudo tee -a "$allowed" >/dev/null
fi
