# maitri: pre-create two Helium profiles on first install — "Work" (Spark) and
# "Personal" (Orchid). EXPERIMENTAL: assumes a recent Chromium profile schema. Does
# nothing if Helium has already run, so it never clobbers existing profiles.
#
# Helium's Linux user-data dir is ~/.config/net.imput.helium (set in helium-linux's
# change-chromium-branding.patch: data_dir_basename = "net.imput.helium"). Official
# release builds get no channel suffix; only non-official "dev" builds append ".dev".
#
# Note: Chromium only supports its built-in illustration avatars (or a Google-account
# photo) for local profiles — a custom image (the brand heart) can't be set this way.

helium_dir="$HOME/.config/net.imput.helium"

if [[ ! -e "$helium_dir/Local State" ]]; then
  python3 - "$helium_dir" <<'PY'
import json, os, sys
d = sys.argv[1]

def skcolor(hexrgb):
    v = int("FF" + hexrgb, 16)            # opaque ARGB SkColor
    return v - (1 << 32) if v >= (1 << 31) else v

WORK = skcolor("82AAFF")  # Spark blue
PERSONAL = skcolor("E59BFF")  # Orchid magenta

ONEPASSWORD = "khgocmkkpikpnmmkgmdnfckapcdkgfaf"  # 1Password beta extension

for sub in ("Default", "Profile 1"):
    os.makedirs(os.path.join(d, sub), exist_ok=True)

local_state = {
    "profile": {
        "info_cache": {
            "Default":   {"name": "Work", "is_using_default_name": False,
                          "avatar_icon": "chrome://theme/IDR_PROFILE_AVATAR_26"},
            "Profile 1": {"name": "Personal", "is_using_default_name": False,
                          "avatar_icon": "chrome://theme/IDR_PROFILE_AVATAR_30"},
        },
        "profiles_order": ["Default", "Profile 1"],
        "last_used": "Default",
        "last_active_profiles": ["Default"],
    }
}
json.dump(local_state, open(os.path.join(d, "Local State"), "w"), indent=2)

def prefs(name, color):
    return {
        "profile": {"name": name},
        # is_grayscale2 is the key the current Helium reads (older is_grayscale is ignored).
        "browser": {"theme": {"user_color": color, "color_scheme": 1, "is_grayscale2": False}},
        "extensions": {
            "theme": {"id": ""},
            # Pin 1Password to the toolbar by default (preinstalled via managed policy
            # in browser-extensions.sh).
            "pinned_extensions": [ONEPASSWORD],
        },
        # Helium-specific defaults. Pre-consent to Helium services so the 1Password
        # extension we preinstall via managed policy actually downloads: Helium is
        # ungoogled-chromium and routes all Web Store downloads through its services
        # proxy (proxy-extension-downloads.patch in imputnet/helium), gated on
        # services.enabled && services.user_consented && services.ext_proxy.
        # user_consented defaults to false until onboarding, so without this the
        # policy-listed extension is silently skipped from every update check. Keys
        # verified against the installed helium binary's pref_names. The user can still
        # change all of this later.
        "helium": {
            "completed_onboarding": True,
            "services": {
                "enabled": True,
                "user_consented": True,
                "ext_proxy": True,
                "bangs": True,
                "browser_updates": False,   # maitri updates Helium via AUR/pacman, not in-browser
                "spellcheck_files": True,
                "ublock_assets": True,
                "disable_schema_alerts": False,
                "schema_version": 1,
            },
        },
        # Vertical tabs are Helium's default layout; lock the strip width/collapse state.
        "vertical_tabs": {"collapsed_state": False, "uncollapsed_width": 200},
        # Default to Google search (changeable by the user). prepopulate_id 1 binds it to
        # Google's built-in engine definition.
        "default_search_provider_data": {
            "template_url_data": {
                "short_name": "Google",
                "keyword": "google.com",
                "url": "https://www.google.com/search?q={searchTerms}",
                "suggestions_url": "https://www.google.com/complete/search?output=chrome&q={searchTerms}",
                "favicon_url": "https://www.google.com/favicon.ico",
                "prepopulate_id": 1,
                "is_active": 1,
                "safe_for_autoreplace": True,
            },
        },
        # Privacy hardening: disable Privacy Sandbox (Topics, FLEDGE, ad measurement) and
        # First-Party Sets.
        "privacy_sandbox": {
            "first_party_sets_enabled": False,
            "m1": {"ad_measurement_enabled": False, "fledge_enabled": False, "topics_enabled": False},
        },
    }

json.dump(prefs("Work", WORK), open(os.path.join(d, "Default", "Preferences"), "w"), indent=2)
json.dump(prefs("Personal", PERSONAL), open(os.path.join(d, "Profile 1", "Preferences"), "w"), indent=2)
print("maitri: seeded Helium profiles — Work (Spark) + Personal (Orchid)")
PY
fi
