#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/XGlass.app"
DMG_PATH="${1:-$DIST_DIR/XGlass-Apple-Silicon.dmg}"
BUILD_CONFIGURATION="${XGLASS_BUILD_CONFIGURATION:-release}"
SIGNING_IDENTITY="${XGLASS_SIGNING_IDENTITY:-${SIGNING_IDENTITY:-}}"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/xglass-dmg.XXXXXX")"

cleanup() {
  rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

if [[ "${XGLASS_SKIP_BUILD:-0}" != "1" ]]; then
  XGLASS_BUILD_CONFIGURATION="$BUILD_CONFIGURATION" \
    XGLASS_SIGNING_IDENTITY="$SIGNING_IDENTITY" \
    "$ROOT_DIR/script/build_and_run.sh" build
fi

test -d "$APP_BUNDLE"
ditto --norsrc --noextattr --noqtn "$APP_BUNDLE" "$STAGING_DIR/XGlass.app"
codesign --verify --deep --strict "$STAGING_DIR/XGlass.app"
ln -s /Applications "$STAGING_DIR/Applications"

rm -f "$DMG_PATH"
mkdir -p "$(dirname "$DMG_PATH")"
hdiutil create \
  -volname "XGlass" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  -imagekey zlib-level=9 \
  "$DMG_PATH"

if [[ -n "$SIGNING_IDENTITY" && "$SIGNING_IDENTITY" != "-" ]]; then
  codesign --force --timestamp --sign "$SIGNING_IDENTITY" "$DMG_PATH"
fi

hdiutil verify "$DMG_PATH"
echo "$DMG_PATH"
