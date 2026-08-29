#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_CONFIGURATION="${XGLASS_BUILD_CONFIGURATION:-debug}"

cd "$ROOT_DIR"
swift package resolve
swift build --product XGlass --configuration "$BUILD_CONFIGURATION"

echo "XGlass SwiftPM build passed (${BUILD_CONFIGURATION})."
