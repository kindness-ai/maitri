# maitri ISO builder

Builds a bootable maitri installer ISO — boot it on bare metal (or a VM), pick your options in the
configurator, and it installs maitri for you. No existing Arch install needed.

This is a rebranded, slimmed fork of Omarchy's ISO builder, repointed at
[`kindness-ai/maitri`](https://github.com/kindness-ai/maitri). It rides maitri's package channel and
signing key (see [`../maitri.md`](../maitri.md)).

## How it works

`builder/build-iso.sh` runs inside an `archlinux/archlinux` container and:
1. Imports the maitri package signing key and installs `maitri-keyring`.
2. Bases the ISO on archiso's `releng` profile (from the `archiso` package — no submodule).
3. Clones the maitri installer (`MAITRI_INSTALLER_REPO`@`MAITRI_INSTALLER_REF`, default
   `kindness-ai/maitri`@`main`) into the live environment.
4. Downloads every package maitri needs into an **offline mirror** baked into the ISO, so the install
   works without a network connection.
5. Runs `mkarchiso` to assemble the ISO into `./release/`.

On boot, the live ISO auto-runs the **maitri Configurator** (a front-end to `archinstall`), installs base
Arch, then runs the maitri installer (`install.sh`) — the same flow as the upstream Omarchy ISO.

## Building

**In CI (recommended):** the [`Build maitri ISO`](../.github/workflows/build-iso.yml) GitHub Action builds
it on a runner and uploads the ISO as a downloadable artifact. Trigger it from the repo's **Actions** tab →
*Build maitri ISO* → *Run workflow*.

**Locally** (needs Linux + Docker; ~30GB free disk):
```bash
./iso/bin/maitri-iso-make --no-boot-offer
# output lands in ./release/
```
Override what gets baked in:
```bash
MAITRI_INSTALLER_REF=some-branch MAITRI_MIRROR=edge ./iso/bin/maitri-iso-make
```

## Testing the ISO

On a Linux host with QEMU: `./iso/bin/maitri-iso-boot release/maitri-main.iso`
(or attach the ISO to any VM — UTM/VMware/VirtualBox/Parallels).

## What's different from Omarchy's ISO builder

- Repointed installer repo → `kindness-ai/maitri`@`main`; mirror defaults to `stable`.
- Boot menus, ISO label/name/publisher, and configurator text say **maitri**.
- Dropped the `archiso` git submodule (uses the packaged `releng` profile instead).
- Dropped the upstream CDN release tooling; for now maitri distributes test builds via the GitHub Action
  artifact. Public ISO hosting is being finalized (see [`../RELEASING.md`](../RELEASING.md)).

## Not yet wired up (phase 2)

- **rc/edge channels** and `--dev`/`--rc` flags assume branches/mirrors maitri doesn't maintain yet.
- **Signed public releases + a stable download URL** (e.g. `maitri.kindness.ai/download`) — needs a public
  host for the ~7 GB offline ISO, or a slimmer online ISO. Tracked in [`../RELEASING.md`](../RELEASING.md).
