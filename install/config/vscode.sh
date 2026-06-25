mkdir -p ~/.vscode

# Pre-populate argv.json with all keys VSCode expects so it doesn't overwrite on
# first launch and clobber the password-store setting.
cat > ~/.vscode/argv.json << EOF
{
  "password-store": "gnome-libsecret",
  "enable-crash-reporter": true,
  "crash-reporter-id": "$(uuidgen)"
}
EOF
