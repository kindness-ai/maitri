MAITRI_MIGRATIONS_STATE_PATH=~/.local/state/maitri/migrations
mkdir -p $MAITRI_MIGRATIONS_STATE_PATH

shopt -s nullglob
for file in ~/.local/share/maitri/migrations/*.sh; do
  touch "$MAITRI_MIGRATIONS_STATE_PATH/$(basename "$file")"
done
