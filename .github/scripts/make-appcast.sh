#!/usr/bin/env bash
#
# Generates a signed Sparkle appcast.xml for the DMG in OUT_DIR.
#
# Sparkle's generate_appcast reads the app's Info.plist inside each archive,
# signs the entry with an EdDSA private key, and writes appcast.xml. The
# download URLs point at the GitHub Release assets for TAG so that SUFeedURL
# (releases/latest/download/appcast.xml) can serve the newest feed.
#
# Usage: make-appcast.sh <owner/repo> <tag> <version> [dist-dir]
#
# Environment:
#   SPARKLE_PRIVATE_KEY  EdDSA private key exported by `generate_keys -x`.
#                        Required; the caller should skip when it is unset.
#   SPARKLE_VERSION      Sparkle release to fetch the CLI tools from
#                        (default 2.10.0, matching the SPM dependency).
#
# Progress goes to stderr; the appcast path is the last line of stdout.
#
set -eo pipefail

REPO="${1:?usage: make-appcast.sh <owner/repo> <tag> <version> [dist-dir]}"
TAG="${2:?usage: make-appcast.sh <owner/repo> <tag> <version> [dist-dir]}"
VERSION="${3:?usage: make-appcast.sh <owner/repo> <tag> <version> [dist-dir]}"
OUT_DIR="${4:-dist}"

SPARKLE_VERSION="${SPARKLE_VERSION:-2.10.0}"
TOOLS_DIR="$(mktemp -d)"
trap 'rm -rf "$TOOLS_DIR"' EXIT

[ -n "${SPARKLE_PRIVATE_KEY:-}" ] || { echo "error: SPARKLE_PRIVATE_KEY is not set" >&2; exit 1; }
[ -d "$OUT_DIR" ] || { echo "error: $OUT_DIR not found" >&2; exit 1; }

echo "Fetching Sparkle ${SPARKLE_VERSION} tools ..." >&2
ARCHIVE="Sparkle-${SPARKLE_VERSION}.tar.xz"
curl -fsSL "https://github.com/sparkle-project/Sparkle/releases/download/${SPARKLE_VERSION}/${ARCHIVE}" -o "$TOOLS_DIR/$ARCHIVE"
tar -xf "$TOOLS_DIR/$ARCHIVE" -C "$TOOLS_DIR"
GENERATE="$TOOLS_DIR/bin/generate_appcast"
[ -x "$GENERATE" ] || { echo "error: generate_appcast not found in the Sparkle tools archive" >&2; exit 1; }

DOWNLOAD_URL_PREFIX="https://github.com/${REPO}/releases/download/${TAG}/"
APPCAST="${OUT_DIR}/appcast.xml"

echo "Generating ${APPCAST} (download prefix: ${DOWNLOAD_URL_PREFIX}) ..." >&2
# --ed-key-file - reads the private key from stdin so it never hits disk.
printf '%s' "${SPARKLE_PRIVATE_KEY}" | "$GENERATE" \
  --ed-key-file - \
  --download-url-prefix "${DOWNLOAD_URL_PREFIX}" \
  --link "https://github.com/${REPO}/releases/tag/${TAG}" \
  -o "${APPCAST}" \
  "${OUT_DIR}"

[ -f "$APPCAST" ] || { echo "error: ${APPCAST} was not created" >&2; exit 1; }
echo "Wrote ${APPCAST} for ${VERSION}" >&2
printf '%s\n' "$APPCAST"
