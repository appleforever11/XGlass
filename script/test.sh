#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_CONFIGURATION="${XGLASS_BUILD_CONFIGURATION:-debug}"
TEST_BUILD_CONFIGURATION="${XGLASS_TEST_BUILD_CONFIGURATION:-debug}"

cd "$ROOT_DIR"

WEB_VIEW_SOURCE="$ROOT_DIR/Sources/XGlass/XWebView.swift"
if /usr/bin/grep -En 'new MutationObserver\(scheduleOverrides\)|setInterval\(' "$WEB_VIEW_SOURCE" >/dev/null; then
    echo "XGlass performance guard failed: unbounded DOM scheduling was reintroduced." >&2
    exit 1
fi
if ! /usr/bin/grep -Eq 'minimumPaintInterval = 250' "$WEB_VIEW_SOURCE"; then
    echo "XGlass performance guard failed: bounded DOM scheduling is missing." >&2
    exit 1
fi

swift package resolve
swift build --product XGlass --configuration "$BUILD_CONFIGURATION"

TEST_BUILD_PATH="$(mktemp -d "${TMPDIR:-/tmp}/XGlassTests.XXXXXX")"
swift build --build-tests --configuration "$TEST_BUILD_CONFIGURATION" --build-path "$TEST_BUILD_PATH"

# SwiftPM does not bundle binary package frameworks into an XCTest bundle.
# Stage Sparkle beside the test product so the test runner can load XGlass.
SPARKLE_FRAMEWORK="$TEST_BUILD_PATH/out/Products/${TEST_BUILD_CONFIGURATION^}/Sparkle.framework"
TEST_FRAMEWORKS="$TEST_BUILD_PATH/out/Products/${TEST_BUILD_CONFIGURATION^}/PackageFrameworks"
if [[ -d "$SPARKLE_FRAMEWORK" ]]; then
    mkdir -p "$TEST_FRAMEWORKS"
    cp -R "$SPARKLE_FRAMEWORK" "$TEST_FRAMEWORKS/"
fi

swift test --configuration "$TEST_BUILD_CONFIGURATION" --skip-build --parallel --build-path "$TEST_BUILD_PATH"

echo "XGlass SwiftPM build passed (${BUILD_CONFIGURATION}); tests passed (${TEST_BUILD_CONFIGURATION})."
