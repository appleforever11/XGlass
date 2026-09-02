#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="XGlass"
APP_DIR="$ROOT_DIR/dist/$APP_NAME.app"
SOURCE_ICON="$ROOT_DIR/Sources/XGlass/Resources/XGlass.icns"
BUILD_CONFIGURATION="${XGLASS_BUILD_CONFIGURATION:-debug}"
SIGNING_IDENTITY="${XGLASS_SIGNING_IDENTITY:-${SIGNING_IDENTITY:-}}"
STAGING_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/xglass-build.XXXXXX")"
STAGED_APP_DIR="$STAGING_ROOT/$APP_NAME.app"
STAGED_CONTENTS_DIR="$STAGED_APP_DIR/Contents"
STAGED_MACOS_DIR="$STAGED_CONTENTS_DIR/MacOS"
STAGED_RESOURCES_DIR="$STAGED_CONTENTS_DIR/Resources"
STAGED_FRAMEWORKS_DIR="$STAGED_CONTENTS_DIR/Frameworks"
POST_COPY_VERIFY_ROOT=""

cleanup() {
  rm -rf "$STAGING_ROOT"
  if [[ -n "$POST_COPY_VERIFY_ROOT" ]]; then
    rm -rf "$POST_COPY_VERIFY_ROOT"
  fi
}
trap cleanup EXIT

cd "$ROOT_DIR"
if [[ ! -f "$SOURCE_ICON" ]]; then
  "$ROOT_DIR/scripts/build-xglass-icon.sh"
fi

if [[ -z "$SIGNING_IDENTITY" ]]; then
  for identity_pattern in 'Developer ID Application' 'Apple Development'; do
    SIGNING_IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null | awk -F'"' -v pattern="$identity_pattern" '$0 ~ /^[[:space:]]*[0-9]+\)/ && index($2, pattern) {print $2; exit}')"
    [[ -n "$SIGNING_IDENTITY" ]] && break
  done
  if [[ -z "$SIGNING_IDENTITY" ]]; then
    SIGNING_IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null | awk -F'"' '/^[[:space:]]*[0-9]+\)/ {print $2; exit}')"
  fi
fi
SIGNING_IDENTITY="${SIGNING_IDENTITY:--}"

swift package resolve
swift build --product "$APP_NAME" --configuration "$BUILD_CONFIGURATION"
BIN_PATH="$(swift build --show-bin-path --configuration "$BUILD_CONFIGURATION")"

SPARKLE_FRAMEWORK="${SPARKLE_FRAMEWORK_PATH:-$ROOT_DIR/.build/artifacts/sparkle/Sparkle/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework}"
if [[ ! -d "$SPARKLE_FRAMEWORK" ]]; then
  SPARKLE_FRAMEWORK="$(find "$ROOT_DIR/.build/artifacts/sparkle" -type d -path '*/Sparkle.framework' -print -quit 2>/dev/null || true)"
fi
if [[ ! -d "$SPARKLE_FRAMEWORK" ]]; then
  echo "Sparkle.framework was not found after dependency resolution." >&2
  exit 1
fi

strip_bundle_metadata() {
  local bundle_path="$1"
  for attribute in com.apple.FinderInfo 'com.apple.fileprovider.fpfs#P' com.apple.provenance; do
    /usr/bin/xattr -r -d "$attribute" "$bundle_path" >/dev/null 2>&1 || true
  done
}

rm -rf "$STAGED_APP_DIR"
mkdir -p "$STAGED_MACOS_DIR" "$STAGED_RESOURCES_DIR" "$STAGED_FRAMEWORKS_DIR"
cp "$BIN_PATH/$APP_NAME" "$STAGED_MACOS_DIR/$APP_NAME"
cp "Sources/XGlass/Info.plist" "$STAGED_CONTENTS_DIR/Info.plist"
cp "$SOURCE_ICON" "$STAGED_RESOURCES_DIR/XGlass.icns"
ditto --norsrc --noextattr --noqtn "$SPARKLE_FRAMEWORK" "$STAGED_FRAMEWORKS_DIR/Sparkle.framework"
chmod +x "$STAGED_MACOS_DIR/$APP_NAME"

install_name_tool \
  -change "@rpath/Sparkle.framework/Versions/B/Sparkle" \
  "@loader_path/../Frameworks/Sparkle.framework/Versions/B/Sparkle" \
  "$STAGED_MACOS_DIR/$APP_NAME"

strip_bundle_metadata "$STAGED_APP_DIR"

if [[ "$SIGNING_IDENTITY" == "-" ]]; then
  if [[ "$BUILD_CONFIGURATION" == "release" ]]; then
    echo "Warning: building a release bundle ad-hoc signed; set XGLASS_SIGNING_IDENTITY for a stable distribution signature." >&2
  fi
  codesign --force --deep --sign - "$STAGED_FRAMEWORKS_DIR/Sparkle.framework"
  codesign --force --deep --sign - "$STAGED_APP_DIR"
else
  if [[ "$BUILD_CONFIGURATION" == "release" || "$SIGNING_IDENTITY" == Developer\ ID\ Application:* ]]; then
    TIMESTAMP_ARGUMENT="--timestamp"
  else
    TIMESTAMP_ARGUMENT="--timestamp=none"
  fi
  codesign --force --deep --options runtime "$TIMESTAMP_ARGUMENT" --sign "$SIGNING_IDENTITY" "$STAGED_FRAMEWORKS_DIR/Sparkle.framework"
  codesign --force --deep --options runtime "$TIMESTAMP_ARGUMENT" --sign "$SIGNING_IDENTITY" "$STAGED_APP_DIR"
fi

# File-provider metadata can be reattached while the nested framework is being
# signed. Strip it once more so ZIP, DMG, and notarization validation see the
# exact signed payload.
strip_bundle_metadata "$STAGED_APP_DIR"
codesign --verify --deep --strict "$STAGED_APP_DIR"

rm -rf "$APP_DIR"
ditto --norsrc --noextattr --noqtn "$STAGED_APP_DIR" "$APP_DIR"
strip_bundle_metadata "$APP_DIR"
POST_COPY_VERIFY_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/xglass-post-copy-verify.XXXXXX")"
ditto --norsrc --noextattr --noqtn "$APP_DIR" "$POST_COPY_VERIFY_ROOT/XGlass.app"
codesign --verify --deep --strict "$POST_COPY_VERIFY_ROOT/XGlass.app"

echo "$APP_DIR"
