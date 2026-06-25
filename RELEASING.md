# Releasing maitri

Cutting a release builds and publishes a maitri ISO. Publishing a GitHub Release triggers
[`build-iso.yml`](.github/workflows/build-iso.yml), which builds the installer ISO from the release tag.

## Versioning

maitri uses **SemVer** tags: `vMAJOR.MINOR.PATCH`.

- `v0.x.y` — pre-stable (where we are now). Anything can change.
- `v1.0.0` — first "this is solid, install it on your daily machine" release.
- After 1.0: **major** = breaking/disruptive change, **minor** = new apps/features, **patch** = fixes.

(Any `v3.x` tags in history are inherited Omarchy tags from the original fork, not maitri releases.)

## Release notes

Notes are **auto-generated from merged pull requests** since the previous release
(`gh release create --generate-notes`). For good notes, land changes via PRs with clear titles; a direct
push to `main` won't show up as a line item.

## How to cut a release

```bash
# 1. Find the latest release and compute the next version
gh release list -R kindness-ai/maitri
NEXT=v0.2.0   # bumped from the latest tag per the requested level

# 2. Create the release off main HEAD with PR-based notes (this triggers the ISO build)
gh release create "$NEXT" \
  --repo kindness-ai/maitri \
  --target main \
  --title "maitri $NEXT" \
  --generate-notes
```

Then `build-iso.yml` runs (~20–40 min) and builds the ISO from the `$NEXT` tag.

## Test builds (no release)

To build an ISO without publishing a release: **Actions → Build maitri ISO → Run workflow** (or
`gh workflow run build-iso.yml`). The ISO is uploaded as a workflow **artifact**.

## ISO hosting

The offline ISO is ~7 GB, which exceeds GitHub's 2 GiB release-asset limit, so it can't attach directly to
a release. On a published release, `build-iso.yml` pushes the ISO to **Docker Hub as an OCI artifact** (via
[ORAS](https://oras.land)) and appends a download link to the release notes.

This needs three repo settings (Settings → Secrets and variables → Actions):

- `DOCKERHUB_USERNAME` (secret) — Docker Hub login
- `DOCKERHUB_TOKEN` (secret) — a Docker Hub access token with read/write
- `DOCKERHUB_NAMESPACE` (variable, optional) — namespace the `maitri-iso` repo lives under (defaults to the username)

Create a **public** `maitri-iso` repository on Docker Hub first. Users then download with:

```sh
oras pull docker.io/<namespace>/maitri-iso:<tag>
```
