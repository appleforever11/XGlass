#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/XGlass.app"
BUILD_CONFIGURATION="${XGLASS_BUILD_CONFIGURATION:-release}"
SIGNING_IDENTITY="${XGLASS_SIGNING_IDENTITY:-${SIGNING_IDENTITY:-}}"

if [[ $# -ge 1 ]]; then
  VERSION="$1"
else
  VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT_DIR/Sources/XGlass/Info.plist")"
fi
ARCHIVE_PATH="${2:-$DIST_DIR/XGlass-${VERSION}-arm64.zip}"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/xglass-release.XXXXXX")"

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
mkdir -p "$(dirname "$ARCHIVE_PATH")"
rm -f "$ARCHIVE_PATH"
ditto -c -k --norsrc --noextattr --noqtn --keepParent "$STAGING_DIR/XGlass.app" "$ARCHIVE_PATH"

echo "$ARCHIVE_PATH"
