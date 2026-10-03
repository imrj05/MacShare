#!/usr/bin/env bash
#
# Bumps MARKETING_VERSION in the Xcode project - the single version read by
# read-version.sh and tagged by auto-tag.sh. CURRENT_PROJECT_VERSION is left
# alone; the release workflow sets it to the CI run number.
#
# Usage: bump-version.sh <major|minor|patch|X.Y.Z> [path/to/project.pbxproj]
#
# The new version is the last line of stdout; progress goes to stderr.
#
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUMP="${1:?usage: bump-version.sh <major|minor|patch|X.Y.Z> [path/to/project.pbxproj]}"
PBXPROJ="${2:-MacShare.xcodeproj/project.pbxproj}"

[ -f "$PBXPROJ" ] || { echo "error: $PBXPROJ not found" >&2; exit 1; }

CURRENT="$("${SCRIPT_DIR}/read-version.sh" "$PBXPROJ")"

if printf '%s' "$BUMP" | grep -Eq '^[0-9]+\.[0-9]+(\.[0-9]+)*$'; then
  NEW="$BUMP"
else
  IFS=. read -r MAJOR MINOR PATCH <<< "$CURRENT"
  MAJOR="${MAJOR:-0}"
  MINOR="${MINOR:-0}"
  PATCH="${PATCH:-0}"
  case "$BUMP" in
    major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
    minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
    patch) PATCH=$((PATCH + 1)) ;;
    *) echo "error: expected major, minor, patch or X.Y.Z (got '$BUMP')" >&2; exit 1 ;;
  esac
  NEW="${MAJOR}.${MINOR}.${PATCH}"
fi

if [ "$NEW" = "$CURRENT" ]; then
  echo "error: $NEW is already the project version" >&2
  exit 1
fi

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
# Written through a temp file so the project file keeps its permissions.
sed -e "s/MARKETING_VERSION = [^;]*;/MARKETING_VERSION = ${NEW};/" "$PBXPROJ" > "$TMP"
cat "$TMP" > "$PBXPROJ"
rm -f "$TMP"
trap - EXIT

# read-version.sh also verifies that every configuration agrees.
VERIFY="$("${SCRIPT_DIR}/read-version.sh" "$PBXPROJ")"
[ "$VERIFY" = "$NEW" ] || { echo "error: $PBXPROJ now reports $VERIFY" >&2; exit 1; }

echo "MARKETING_VERSION: ${CURRENT} -> ${NEW}" >&2
echo "Next:" >&2
echo "  git add ${PBXPROJ}" >&2
echo "  git commit -m 'chore(release): bump version to ${NEW}'" >&2
echo "  git push    # CI tags v${NEW} and runs the release workflow" >&2
printf '%s\n' "$NEW"
