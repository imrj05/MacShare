#!/usr/bin/env bash
#
# Prepends a generated release section to the CHANGELOG file, keeping a single
# "# Changelog" header at the top. Re-running a release replaces that version's
# existing section rather than duplicating it. Sections end up in write order,
# so a normal forward release is newest-first; re-running an older release moves
# that section back to the top.
#
# Usage: update-changelog.sh <notes-file> [changelog-file]
#
set -eo pipefail

NOTES="${1:?usage: update-changelog.sh <notes-file> [changelog-file]}"
FILE="${2:-CHANGELOG}"

[ -s "$NOTES" ] || { echo "error: $NOTES is empty" >&2; exit 1; }

TMP="$(mktemp)"
DROP="$(mktemp)"
trap 'rm -f "$TMP" "$DROP"' EXIT

if [ ! -s "$FILE" ] || ! head -n 1 "$FILE" | grep -q '^# '; then
  {
    printf '# Changelog\n\n'
    if [ -s "$FILE" ]; then cat "$FILE"; fi
  } > "$TMP"
  mv "$TMP" "$FILE"
fi

# Version token from the notes heading: "v0.1.0" out of "## v0.1.0 — 2026-10-04".
VERSION_TOKEN="$(head -n 1 "$NOTES" | awk '{ print $2 }')"
if [ -z "$VERSION_TOKEN" ]; then
  echo "error: no version token on the first line of $NOTES" >&2
  exit 1
fi

# Remove any existing section for this version. Matching the whole token keeps
# v0.0.1 and v0.0.10 apart.
awk -v ver="$VERSION_TOKEN" '
  /^## / {
    skip = 0
    if ($2 == ver) { skip = 1; next }
  }
  !skip { print }
' "$FILE" > "$DROP"
if ! cmp -s "$FILE" "$DROP"; then
  echo "Replacing the existing ${VERSION_TOKEN} section in $FILE"
  mv "$DROP" "$FILE"
fi

# First existing "## " release section; anything before it is the file header.
FIRST_SECTION="$(grep -n '^## ' "$FILE" | head -n 1 | cut -d: -f1 || true)"

# Everything before the first section, with trailing blank lines removed.
header() {
  if [ -n "$FIRST_SECTION" ] && [ "$FIRST_SECTION" -gt 1 ]; then
    head -n "$((FIRST_SECTION - 1))" "$FILE"
  else
    cat "$FILE"
  fi | awk '{ line[NR] = $0 } END { last = NR; while (last > 0 && line[last] == "") last--; for (i = 1; i <= last; i++) print line[i] }'
}

{
  header
  printf '\n'
  cat "$NOTES"
  printf '\n'
  if [ -n "$FIRST_SECTION" ] && [ "$FIRST_SECTION" -gt 1 ]; then
    tail -n "+${FIRST_SECTION}" "$FILE"
  fi
} > "$TMP"

# Trim trailing blank lines so repeated releases produce a stable file.
awk '{ line[NR] = $0 } END { last = NR; while (last > 0 && line[last] == "") last--; for (i = 1; i <= last; i++) print line[i] }' "$TMP" > "$DROP"
mv "$DROP" "$FILE"
echo "Updated $FILE"
