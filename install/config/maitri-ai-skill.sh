# Place in each assistant's global skills directory so the maitri skill is available on first install
mkdir -p ~/.agents/skills ~/.claude/skills ~/.codex/skills ~/.pi/agent/skills
ln -sfn "$MAITRI_PATH/default/maitri-skill" ~/.agents/skills/maitri
ln -sfn "$MAITRI_PATH/default/maitri-skill" ~/.claude/skills/maitri
ln -sfn "$MAITRI_PATH/default/maitri-skill" ~/.codex/skills/maitri
ln -sfn "$MAITRI_PATH/default/maitri-skill" ~/.pi/agent/skills/maitri
