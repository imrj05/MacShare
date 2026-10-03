#!/usr/bin/env bash
#
# Packages a built .app into a compressed DMG with an /Applications shortcut.
#
# Usage: make-dmg.sh <path-to-.app> <version> [output-dir]
#
# Progress goes to stderr; the DMG path is the last line of stdout.
#
set -eo pipefail

APP="${1:?usage: make-dmg.sh <path-to-.app> <version> [output-dir]}"
VERSION="${2:?usage: make-dmg.sh <path-to-.app> <version> [output-dir]}"
OUT_DIR="${3:-dist}"

[ -d "$APP" ] || { echo "error: $APP not found" >&2; exit 1; }

APP_NAME="$(basename "$APP")"
APP_BASENAME="${APP_NAME%.app}"

VOL_NAME="$(plutil -extract CFBundleDisplayName raw -o - "$APP/Contents/Info.plist" 2>/dev/null || true)"
[ -n "$VOL_NAME" ] || VOL_NAME="$APP_BASENAME"

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

echo "Staging $APP_NAME ..." >&2
ditto "$APP" "$STAGE/$APP_NAME"
ln -s /Applications "$STAGE/Applications"

mkdir -p "$OUT_DIR"
DMG="${OUT_DIR}/${APP_BASENAME}-${VERSION}.dmg"
rm -f "$DMG"

# macOS 26 deprecated `hdiutil create -srcfolder`; prefer the replacement and
# fall back for older images (macos-15 and earlier).
echo "Creating $DMG (volume name: $VOL_NAME) ..." >&2
rm -f "$DMG"
if diskutil image create from --help >/dev/null 2>&1; then
  if diskutil image create from --format UDZO --volumeName "$VOL_NAME" "$STAGE" "$DMG" >&2; then
    :
  else
    echo "diskutil image create failed; falling back to hdiutil" >&2
    rm -f "$DMG"
  fi
fi
if [ ! -f "$DMG" ]; then
  hdiutil create -volname "$VOL_NAME" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >&2
fi
hdiutil verify "$DMG" >&2

DMG_BASENAME="$(basename "$DMG")"
( cd "$OUT_DIR" && shasum -a 256 "$DMG_BASENAME" | tee "${DMG_BASENAME}.sha256" )

echo "$DMG"
