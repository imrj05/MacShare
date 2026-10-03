#!/usr/bin/env bash
#
# Prepends a generated release section to the CHANGELOG file, keeping a single
# "# Changelog" header at the top and never losing previously written sections.
#
# Usage: update-changelog.sh <notes-file> [changelog-file]
#
set -eo pipefail

NOTES="${1:?usage: update-changelog.sh <notes-file> [changelog-file]}"
FILE="${2:-CHANGELOG}"

[ -s "$NOTES" ] || { echo "error: $NOTES is empty" >&2; exit 1; }

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

if [ ! -s "$FILE" ] || ! head -n 1 "$FILE" | grep -q '^# '; then
  {
    printf '# Changelog\n\n'
    if [ -s "$FILE" ]; then cat "$FILE"; fi
  } > "$TMP"
  mv "$TMP" "$FILE"
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

mv "$TMP" "$FILE"
echo "Updated $FILE"
