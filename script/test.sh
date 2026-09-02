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

# Xcode-backed SwiftPM builds put binary frameworks beside an XCTest bundle,
# whose generated rpath points at a PackageFrameworks directory. Native
# SwiftPM builds keep Sparkle beside the test executable and need no staging.
TEST_BUNDLE="$(find "$TEST_BUILD_PATH" -type d -name '*.xctest' -print -quit)"
if [[ -n "$TEST_BUNDLE" ]]; then
    TEST_PRODUCTS_DIR="$(dirname "$TEST_BUNDLE")"
    SPARKLE_FRAMEWORK="$TEST_PRODUCTS_DIR/Sparkle.framework"
    TEST_FRAMEWORKS="$TEST_PRODUCTS_DIR/PackageFrameworks"
    if [[ -d "$SPARKLE_FRAMEWORK" ]]; then
        mkdir -p "$TEST_FRAMEWORKS"
        /usr/bin/ditto "$SPARKLE_FRAMEWORK" "$TEST_FRAMEWORKS/Sparkle.framework"
    fi
fi

swift test --configuration "$TEST_BUILD_CONFIGURATION" --skip-build --parallel --build-path "$TEST_BUILD_PATH"

echo "XGlass SwiftPM build passed (${BUILD_CONFIGURATION}); tests passed (${TEST_BUILD_CONFIGURATION})."
