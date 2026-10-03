#!/usr/bin/env bash
#
# Reads the single MARKETING_VERSION declared in the Xcode project and prints it.
#
# All targets/configurations must agree: the app and its Share Extension ship
# together, and a mismatch would tag one version while shipping another. Any
# disagreement is an error rather than a guess.
#
# Usage: read-version.sh [path/to/project.pbxproj]
#
set -eo pipefail

PBXPROJ="${1:-MacShare.xcodeproj/project.pbxproj}"

[ -f "$PBXPROJ" ] || { echo "error: $PBXPROJ not found" >&2; exit 1; }

VERSIONS="$(grep -o 'MARKETING_VERSION = [^;]*;' "$PBXPROJ" \
  | sed -e 's/^MARKETING_VERSION = //' -e 's/;$//' -e 's/"//g' -e 's/[[:space:]]//g' \
  | grep . \
  | sort -u || true)"

if [ -z "$VERSIONS" ]; then
  echo "error: no MARKETING_VERSION found in $PBXPROJ" >&2
  exit 1
fi

COUNT="$(printf '%s\n' "$VERSIONS" | grep -c .)"

if [ "$COUNT" -gt 1 ]; then
  echo "error: MARKETING_VERSION is inconsistent in $PBXPROJ:" >&2
  printf '  %s\n' $VERSIONS >&2
  grep -n 'MARKETING_VERSION' "$PBXPROJ" >&2
  exit 1
fi

if ! printf '%s' "$VERSIONS" | grep -Eq '^[0-9]+\.[0-9]+(\.[0-9]+)*$'; then
  echo "error: MARKETING_VERSION '$VERSIONS' is not a usable version (expected e.g. 1.2.0)" >&2
  exit 1
fi

printf '%s\n' "$VERSIONS"
