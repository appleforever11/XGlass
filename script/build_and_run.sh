#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="XGlass"
BUNDLE_ID="com.kevinhowe.XGlass"
BUILD_CONFIGURATION="${XGLASS_BUILD_CONFIGURATION:-debug}"
SIGNING_IDENTITY="${XGLASS_SIGNING_IDENTITY:-}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"

cd "$ROOT_DIR"

kill_existing() {
  pkill -x "$APP_NAME" >/dev/null 2>&1 || true
}

build_app() {
  XGLASS_BUILD_CONFIGURATION="$BUILD_CONFIGURATION" \
    XGLASS_SIGNING_IDENTITY="$SIGNING_IDENTITY" \
    "$ROOT_DIR/scripts/build-xglass-app.sh"
}

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

verify_bundle() {
  local staging_dir
  staging_dir="$(mktemp -d "${TMPDIR:-/tmp}/xglass-verify.XXXXXX")"
  ditto --norsrc --noextattr --noqtn "$APP_BUNDLE" "$staging_dir/XGlass.app"
  codesign --verify --deep --strict "$staging_dir/XGlass.app"
  rm -rf "$staging_dir"
}

case "$MODE" in
  build|--build)
    build_app
    ;;
  run)
    kill_existing
    build_app
    open_app
    ;;
  --debug|debug)
    kill_existing
    build_app
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    kill_existing
    build_app
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    kill_existing
    build_app
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    kill_existing
    build_app
    open_app
    sleep 2
    pgrep -x "$APP_NAME" >/dev/null
    verify_bundle
    echo "$APP_NAME is running and the signed bundle verified"
    ;;
  *)
    echo "usage: $0 [build|run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
