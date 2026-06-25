#!/bin/bash

set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
CLI="$ROOT/bin/maitri"
TMPDIR=""

export PATH="$ROOT/bin:$PATH"

pass() {
  printf 'ok - %s\n' "$1"
}

fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

assert_output_contains() {
  local description="$1"
  local output="$2"
  local expected="$3"

  if [[ $output != *"$expected"* ]]; then
    printf 'Expected output to contain: %s\n' "$expected" >&2
    printf 'Actual output:\n%s\n' "$output" >&2
    fail "$description"
  fi

  pass "$description"
}

cleanup() {
  [[ -n $TMPDIR && -d $TMPDIR ]] && rm -rf "$TMPDIR"
}
trap cleanup EXIT

output=$("$CLI" --help)
assert_output_contains "main help renders" "$output" "maitri command center"
assert_output_contains "main help includes hardware group" "$output" "hw"
assert_output_contains "main help includes package group" "$output" "pkg"
if grep -Eq '^  [a-z0-9-]+[[:space:]].*\([0-9]+\)$' <<<"$output"; then
  fail "main help does not show group counts"
fi
pass "main help does not show group counts"

output=$("$CLI" commands)
assert_output_contains "commands lists documented commands" "$output" "maitri theme set <theme-name>"

"$CLI" commands --json | jq -e '.ok == true and (.commands | length >= 200)' >/dev/null
pass "commands --json is valid JSON with full bin coverage"

"$CLI" commands --json | jq -e 'all(.commands[]; .summary != "undocumented")' >/dev/null
pass "all included commands have summaries"

"$CLI" commands --json | jq -e 'all(.commands[]; has("binary") and has("filename_route") and has("routes") and (has("legacy") | not) and (has("usage") | not) and (has("visibility") | not) and (has("mutates") | not) and (has("interactive") | not))' >/dev/null
pass "JSON uses binary/routes and omits legacy/usage/extra metadata"

"$CLI" commands --check >/dev/null
pass "commands --check passes"

"$CLI" commands --all >/dev/null
pass "commands --all does not crash"

"$CLI" commands --all --json | jq -e '.commands[] | select(.route == "maitri hyprland window gaps toggle" and .summary != "undocumented")' >/dev/null
pass "fallback commands are inferred and documented"

"$CLI" commands --all --json | jq -e '.commands[] | select(.route == "maitri dev benchmark")' >/dev/null
pass "benchmark command is discoverable in all commands"

"$CLI" commands --json | jq -e '.commands[] | select(.binary == "maitri-pkg-add" and .route == "maitri pkg add" and .filename_route == "maitri pkg add" and (.routes | index("maitri pkg add")))' >/dev/null
pass "JSON exposes direct pkg add route"

"$CLI" commands --json | jq -e '.commands[] | select(.binary == "maitri-refresh-pacman" and .requires_sudo == true)' >/dev/null
pass "sudo metadata marks sudo commands"

output=$("$CLI" theme --help)
assert_output_contains "group help renders" "$output" "Theme commands"

output=$("$CLI" install --help)
assert_output_contains "install group help renders" "$output" "Install commands"
assert_output_contains "install group includes browser route" "$output" "maitri install browser"

output=$("$CLI" install)
assert_output_contains "bare group renders help instead of picker" "$output" "Install commands"
assert_output_contains "bare group includes browser route" "$output" "maitri install browser"

output=$("$CLI" toggle)
assert_output_contains "bare root command with children renders help" "$output" "Toggle commands"
assert_output_contains "bare toggle help includes child route" "$output" "maitri toggle waybar"

output=$("$CLI" pkg --help)
assert_output_contains "package group includes pkg add fallback route" "$output" "maitri pkg add <packages...>"

output=$("$CLI" restart --help)
assert_output_contains "restart group includes inferred commands" "$output" "maitri restart btop"
assert_output_contains "restart group includes all restart commands" "$output" "maitri restart wifi"

output=$("$CLI" hw --help)
assert_output_contains "hardware group help renders" "$output" "maitri hw asus rog"
assert_output_contains "hardware group includes touchpad" "$output" "maitri hw touchpad"

output=$("$CLI" hw asus)
assert_output_contains "partial hardware prefix renders matching commands" "$output" "maitri hw asus rog"
assert_output_contains "partial hardware prefix includes nested match" "$output" "maitri hw asus zenbook ux5406aa"

output=$("$CLI" menu --help)
assert_output_contains "menu group includes share fallback route" "$output" "maitri menu share"

output=$("$CLI" share)
assert_output_contains "bare required-arg alias renders CLI help" "$output" "Usage:"
assert_output_contains "bare share help uses canonical route" "$output" "maitri share <clipboard|file|folder> [path...]"

output=$("$CLI" menu share)
assert_output_contains "bare required-arg filename route renders CLI help" "$output" "maitri share <clipboard|file|folder> [path...]"

output=$("$CLI" branch set)
assert_output_contains "bare required-choice route renders CLI help" "$output" "maitri branch set <master|rc|dev>"

CLI="$CLI" python3 <<'PY'
import json
import os
import subprocess
import sys

cli = os.environ['CLI']
commands = json.loads(subprocess.check_output([cli, 'commands', '--json'], text=True))['commands']
by_group = {}
for command in commands:
  binary = command['binary']
  stem = binary.removeprefix('maitri-')
  group = stem.split('-', 1)[0]
  filename_route = 'maitri ' + stem.replace('-', ' ')
  by_group.setdefault(group, []).append((binary, filename_route, command['route']))

missing = []
for group, rows in sorted(by_group.items()):
  proc = subprocess.run([cli, group, '--help'], text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  output = proc.stdout + proc.stderr
  if proc.returncode != 0:
    missing.append((group, '<group-help-failed>', f'exit {proc.returncode}'))
    continue
  for binary, filename_route, canonical_route in rows:
    if filename_route not in output and canonical_route not in output and binary not in output:
      missing.append((group, binary, filename_route))

if missing:
  for row in missing:
    print('\t'.join(row), file=sys.stderr)
  sys.exit(1)
PY
pass "every filename-derived group help represents its bins"

output=$(timeout 5 "$CLI" theme set --help)
assert_output_contains "command help renders without executing" "$output" "Binary:"
assert_output_contains "theme set help names binary" "$output" "maitri-theme-set"

output=$(timeout 5 "$CLI" update --help)
assert_output_contains "mutating command help does not execute target" "$output" "maitri-update"
assert_output_contains "root command help shows related child commands" "$output" "maitri update perform"

output=$("$CLI" screenshot --help)
assert_output_contains "root alias resolves to command help" "$output" "maitri-capture-screenshot"

"$CLI" commands --json | jq -e '.commands[] | select(.binary == "maitri-capture-screenshot") | .aliases | index("maitri screenshot")' >/dev/null
pass "aliases are included in JSON metadata"

output=$("$CLI" pkg add --help)
assert_output_contains "pkg add help resolves" "$output" "maitri-pkg-add"
assert_output_contains "pkg add help shows direct route" "$output" "maitri pkg add <packages...>"

output=$("$CLI" system reboot --help)
assert_output_contains "system command help is safe" "$output" "maitri-system-reboot"

output=$("$CLI" dev benchmark --repeat=1)
assert_output_contains "benchmark command runs" "$output" "maitri CLI benchmark"

"$CLI" theme list >/dev/null
pass "safe dispatch works for theme list"

"$CLI" theme current >/dev/null
pass "safe dispatch works for theme current"

"$CLI" font list >/dev/null
pass "safe dispatch works for font list"

"$CLI" font current >/dev/null
pass "safe dispatch works for font current"

for binary in \
  maitri-update \
  maitri-theme-set \
  maitri-capture-screenshot \
  maitri-system-reboot \
  maitri-pkg-add; do
  [[ -x $ROOT/bin/$binary ]] || fail "binary is executable: $binary"
  pass "binary is executable: $binary"
done

while IFS= read -r binary_path; do
  header=$(awk '
    NR == 1 && /^#!/ { next }
    /^[[:space:]]*$/ { if (seen) print; next }
    /^[[:space:]]*#/ { seen=1; print; next }
    { exit }
  ' "$binary_path")

  grep -q '^# maitri:summary=' <<<"$header" || fail "metadata summary is present: $binary_path"
  ! grep -q '^# maitri:binary=' <<<"$header" || fail "metadata does not repeat inferred binary: $binary_path"
  ! grep -q '^# maitri:args=$' <<<"$header" || fail "metadata does not include empty args: $binary_path"
  ! grep -Eq '^# maitri:(legacy|usage|visibility|mutates|interactive)=' <<<"$header" || fail "metadata avoids removed fields: $binary_path"
  ! grep -Eq '^# maitri:requires-sudo=false$' <<<"$header" || fail "metadata omits false booleans: $binary_path"
done < <(find "$ROOT/bin" -maxdepth 1 -type f -executable -name 'maitri-*' | sort)
pass "all executable bins have slim self-documenting metadata"

TMPDIR=$(mktemp -d)
ln -s "$CLI" "$TMPDIR/maitri"

{
  printf '#!/bin/bash\n\n'
  printf '# ordinary comments are fine\n'
  printf '# maitri:this malformed line should be ignored\n'
  printf '# maitri:group=weird\n'
  printf '# maitri:name=test\n'
  printf '# maitri:summary=Survives malformed metadata comments\n'
  printf '# maitri:made-up=value\n'
  printf 'echo weird-ok\n'
} >"$TMPDIR/maitri-weird-test"
chmod +x "$TMPDIR/maitri-weird-test"

{
  printf '#!/bin/bash\n\n'
  printf '# a partial metadata header should not destroy fallback routing\n'
  printf '# maitri:summary=Partial metadata keeps inferred route\n'
  printf '# maitri:made-up=value\n'
  printf 'echo partial-ok\n'
} >"$TMPDIR/maitri-partial-meta-test"
chmod +x "$TMPDIR/maitri-partial-meta-test"

{
  printf '#!/bin/bash\n\n'
  printf 'echo body-metadata-ok\n'
  printf '# maitri:group=wrong\n'
  printf '# maitri:name=wrong\n'
} >"$TMPDIR/maitri-body-metadata-test"
chmod +x "$TMPDIR/maitri-body-metadata-test"

"$TMPDIR/maitri" commands --all --json | jq -e '.commands[] | select(.route == "maitri weird test" and .summary == "Survives malformed metadata comments")' >/dev/null
pass "unknown metadata values are non-fatal"

"$TMPDIR/maitri" commands --all --json | jq -e '.commands[] | select(.route == "maitri partial meta test" and .summary == "Partial metadata keeps inferred route")' >/dev/null
pass "partial metadata keeps inferred fallback route"

"$TMPDIR/maitri" commands --all --json | jq -e '.commands[] | select(.route == "maitri body metadata test" and .summary == "Run the body metadata test command")' >/dev/null
pass "metadata-looking comments after script body are ignored"

output=$("$TMPDIR/maitri" weird test)
assert_output_contains "temporary metadata command dispatches" "$output" "weird-ok"

output=$("$TMPDIR/maitri" partial meta test)
assert_output_contains "partial metadata command dispatches" "$output" "partial-ok"

output=$("$TMPDIR/maitri" body metadata test)
assert_output_contains "body metadata command dispatches by filename" "$output" "body-metadata-ok"
