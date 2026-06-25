# Set identification from install inputs
if [[ -n ${MAITRI_USER_NAME//[[:space:]]/} ]]; then
  git config --global user.name "$MAITRI_USER_NAME"
fi

if [[ -n ${MAITRI_USER_EMAIL//[[:space:]]/} ]]; then
  git config --global user.email "$MAITRI_USER_EMAIL"
fi

# Use VS Code as the git commit editor (maitri default editor)
git config --global core.editor "code --wait"
