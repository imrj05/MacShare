#!/usr/bin/env bash
#
# Packages a built .app into a compressed DMG with an /Applications shortcut
# and a Finder window styled with the background image that ships next to this
# script (background_660x400.tiff). If the Finder cannot be scripted, the DMG
# is still produced without the styling.
#
# Usage: make-dmg.sh <path-to-.app> <version> [output-dir]
#
# Progress goes to stderr; the DMG path is the last line of stdout.
#
set -eo pipefail

APP="${1:?usage: make-dmg.sh <path-to-.app> <version> [output-dir]}"
VERSION="${2:?usage: make-dmg.sh <path-to-.app> <version> [output-dir]}"
OUT_DIR="${3:-dist}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKGROUND="$SCRIPT_DIR/background_660x400.tiff"

# Finder window layout; must match background_660x400.tiff: the app icon sits
# on the left and the arrow points at the Applications shortcut. The logo baked
# into the image stays visible in the middle as artwork.
WINDOW_X=200
WINDOW_Y=120
WINDOW_WIDTH=660
WINDOW_HEIGHT=400
WINDOW_RIGHT=$((WINDOW_X + WINDOW_WIDTH))
WINDOW_BOTTOM=$((WINDOW_Y + WINDOW_HEIGHT))
ICON_SIZE=100
APP_ICON_X=165
APP_ICON_Y=200
DROP_ICON_X=470
DROP_ICON_Y=200

[ -d "$APP" ] || { echo "error: $APP not found" >&2; exit 1; }
[ -f "$BACKGROUND" ] || echo "warning: $BACKGROUND not found; the DMG window will be unstyled" >&2

APP_NAME="$(basename "$APP")"
APP_BASENAME="${APP_NAME%.app}"

VOL_NAME="$(plutil -extract CFBundleDisplayName raw -o - "$APP/Contents/Info.plist" 2>/dev/null || true)"
[ -n "$VOL_NAME" ] || VOL_NAME="$APP_BASENAME"

STAGE="$(mktemp -d)"
WORK="$(mktemp -d)"
MOUNT=""

detach() {
  diskutil eject "$1" >/dev/null 2>&1 || hdiutil detach "$1" >/dev/null 2>&1 || true
}

cleanup() {
  [ -n "$MOUNT" ] && detach "$MOUNT"
  rm -rf "$STAGE" "$WORK"
}
trap cleanup EXIT

echo "Staging $APP_NAME ..." >&2
ditto "$APP" "$STAGE/$APP_NAME"
ln -s /Applications "$STAGE/Applications"
mkdir -p "$STAGE/.background"
[ -f "$BACKGROUND" ] && cp "$BACKGROUND" "$STAGE/.background/background.tiff"

mkdir -p "$OUT_DIR"
DMG="${OUT_DIR}/${APP_BASENAME}-${VERSION}.dmg"
rm -f "$DMG"

# Asks Finder to lay out the mounted volume (window size and position,
# background picture, icon positions). Finder stores the layout in the
# volume's .DS_Store, which survives the conversion to the final image.
# Finder scripting can be unavailable (no GUI session, automation denied), so
# the caller falls back to a plain DMG when this fails.
style_volume() {
  local mount="$1"
  local volume_name
  volume_name="$(basename "$mount")"
  echo "Styling the disk image window ..." >&2
  osascript - "$volume_name" "$mount" "$APP_NAME" <<-APPLESCRIPT
	on run argv
		set diskName to item 1 of argv
		set mountDir to item 2 of argv
		set appName to item 3 of argv
		set theBackground to POSIX file (mountDir & "/.background/background.tiff")

		tell application "Finder"
			with timeout of 120 seconds
				tell disk (diskName as string)
					open
					delay 2
					tell container window
						set current view to icon view
						set toolbar visible to false
						set statusbar visible to false
						set the bounds to {$WINDOW_X, $WINDOW_Y, $WINDOW_RIGHT, $WINDOW_BOTTOM}
					end tell
					tell the icon view options of container window
						set arrangement to not arranged
						set icon size to $ICON_SIZE
						set background picture to theBackground
					end tell
					delay 1
					try
						-- Push every item, including the hidden .background folder,
						-- off the window before placing the icons to show.
						set position of every item of container window to {2000, 2000}
					end try
					set position of item (appName as string) of container window to {$APP_ICON_X, $APP_ICON_Y}
					set position of item "Applications" of container window to {$DROP_ICON_X, $DROP_ICON_Y}
					update without registering applications
					delay 2
					close
					delay 1
				end tell
			end timeout
		end tell
	end run
	APPLESCRIPT
}

create_plain_dmg() {
  echo "Creating $DMG (volume name: $VOL_NAME) ..." >&2
  rm -f "$DMG"
  if diskutil image create from --help >/dev/null 2>&1; then
    if diskutil image create from --format UDZO --volumeName "$VOL_NAME" "$STAGE" "$DMG" >&2; then
      return 0
    fi
    echo "diskutil image create failed; falling back to hdiutil" >&2
    rm -f "$DMG"
  fi
  hdiutil create -volname "$VOL_NAME" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >&2
}

# Builds the styled image through a writable volume: create it, mount it, let
# Finder write the layout, then compress it. macOS 26 deprecated the hdiutil
# flow; use diskutil there and keep hdiutil for older systems.
build_styled_dmg() {
  local rw use_diskutil=1
  echo "Creating $DMG (volume name: $VOL_NAME) ..." >&2
  if diskutil image create from --help >/dev/null 2>&1; then
    # A space in the sparsebundle path makes diskutil treat the bundle as a
    # folder and copy its files into the image instead of converting it.
    rw="$WORK/volume.sparsebundle"
    diskutil image create from --format UDSB --volumeName "$VOL_NAME" "$STAGE" "$rw" >&2 || return 1
    MOUNT="$(diskutil image attach --nobrowse "$rw" | tail -n 1 | awk -F'\t' '{ print $NF }' | sed 's/^[[:space:]]*//')"
  else
    use_diskutil=0
    rw="$WORK/volume.dmg"
    hdiutil create -volname "$VOL_NAME" -srcfolder "$STAGE" -fs HFS+ -format UDRW -ov "$rw" >&2 || return 1
    MOUNT="$(hdiutil attach "$rw" -nobrowse -noautoopen | sed -n 's|.*\(/Volumes/.*\)|\1|p' | tail -n 1)"
  fi
  [ -n "$MOUNT" ] && [ -d "$MOUNT" ] || return 1

  if ! style_volume "$MOUNT"; then
    detach "$MOUNT"
    MOUNT=""
    return 1
  fi

  rm -rf "$MOUNT/.fseventsd"
  sync
  detach "$MOUNT" || return 1
  MOUNT=""

  if [ "$use_diskutil" -eq 1 ]; then
    diskutil image create from --format UDZO "$rw" "$DMG" >&2
  else
    hdiutil convert "$rw" -format UDZO -o "$DMG" >&2
  fi
  [ -f "$DMG" ]
}

if [ -f "$BACKGROUND" ] && build_styled_dmg; then
  :
else
  [ -f "$BACKGROUND" ] && echo "warning: could not style the disk image; building a plain DMG" >&2
  create_plain_dmg
fi
hdiutil verify "$DMG" >&2

DMG_BASENAME="$(basename "$DMG")"
( cd "$OUT_DIR" && shasum -a 256 "$DMG_BASENAME" | tee "${DMG_BASENAME}.sha256" )

echo "$DMG"
