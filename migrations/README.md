# Migrations

`maitri update` runs every `*.sh` in this directory that hasn't run yet, tracked by marker
files in `~/.local/state/maitri/migrations/`. Fresh installs mark them all as already-applied
*without* running them (see `install/preflight/migrations.sh`), so migrations only ever apply
incremental changes to machines that are already installed.

Migration history was reset when the project became independent (renamed from its
upstream/omarchy origins to **maitri**). Everything a fresh install needs is set up by
`install/` — migrations are only for transitioning existing machines forward from here.

Add a new migration as `<unix-timestamp>.sh` (it runs in filename order).

Migrating a legacy `~/.local/share/omarchy` install? That one-time move can't run as a normal
migration — the rename relocates the very commands the updater invokes mid-run — so use the
standalone helper instead:

```bash
maitri migrate-from-omarchy
```
