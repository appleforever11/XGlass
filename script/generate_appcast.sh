#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
VERSION="${1:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT_DIR/Sources/XGlass/Info.plist")}"
ARCHIVE_PATH="${2:-$DIST_DIR/XGlass-${VERSION}-arm64.zip}"
SPARKLE_BIN="${SPARKLE_BIN:-$ROOT_DIR/.build/artifacts/sparkle/Sparkle/bin}"
INPUT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/xglass-appcast.XXXXXX")"

cleanup() {
  rm -rf "$INPUT_DIR"
}
trap cleanup EXIT

test -x "$SPARKLE_BIN/generate_appcast"
test -f "$ARCHIVE_PATH"
test -s "$ROOT_DIR/RELEASE_NOTES/${VERSION}.md"

cp "$ARCHIVE_PATH" "$INPUT_DIR/XGlass-${VERSION}-arm64.zip"
cp "$ROOT_DIR/RELEASE_NOTES/${VERSION}.md" "$INPUT_DIR/XGlass-${VERSION}-arm64.md"

if [[ -f "$DIST_DIR/appcast.xml" ]]; then
  cp "$DIST_DIR/appcast.xml" "$INPUT_DIR/appcast.xml"
fi

APPCAST_ARGS=(
  --account xglass
  --embed-release-notes
  --download-url-prefix "https://github.com/appleforever11/XGlass/releases/download/v${VERSION}/"
  --link "https://github.com/appleforever11/XGlass"
)

if [[ -n "${SPARKLE_PRIVATE_KEY:-}" ]]; then
  printf '%s' "$SPARKLE_PRIVATE_KEY" | "$SPARKLE_BIN/generate_appcast" \
    --ed-key-file - "${APPCAST_ARGS[@]}" "$INPUT_DIR"
else
  "$SPARKLE_BIN/generate_appcast" "${APPCAST_ARGS[@]}" "$INPUT_DIR"
fi

cp "$INPUT_DIR/appcast.xml" "$DIST_DIR/appcast.xml"
echo "$DIST_DIR/appcast.xml"
