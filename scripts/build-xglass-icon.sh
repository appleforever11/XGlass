#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_PNG="$ROOT_DIR/Sources/XGlass/Resources/XGlass-icon.png"
ICONSET_DIR="$ROOT_DIR/dist/XGlass.iconset"
OUTPUT_ICNS="$ROOT_DIR/Sources/XGlass/Resources/XGlass.icns"

if [[ ! -f "$SOURCE_PNG" ]]; then
  echo "Missing source icon at $SOURCE_PNG" >&2
  exit 1
fi

rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

make_icon() {
  local size="$1"
  local output="$2"
  sips -z "$size" "$size" "$SOURCE_PNG" --out "$output" >/dev/null
}

make_icon 16 "$ICONSET_DIR/icon_16x16.png"
make_icon 32 "$ICONSET_DIR/icon_16x16@2x.png"
make_icon 32 "$ICONSET_DIR/icon_32x32.png"
make_icon 64 "$ICONSET_DIR/icon_32x32@2x.png"
make_icon 128 "$ICONSET_DIR/icon_128x128.png"
make_icon 256 "$ICONSET_DIR/icon_128x128@2x.png"
make_icon 256 "$ICONSET_DIR/icon_256x256.png"
make_icon 512 "$ICONSET_DIR/icon_256x256@2x.png"
make_icon 512 "$ICONSET_DIR/icon_512x512.png"
cp "$SOURCE_PNG" "$ICONSET_DIR/icon_512x512@2x.png"

iconutil -c icns "$ICONSET_DIR" -o "$OUTPUT_ICNS"
echo "$OUTPUT_ICNS"
