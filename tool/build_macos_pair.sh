#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/build/macos-pair"
BUILD_MODE="${BUILD_MODE:-release}"
DECK_WS_PORT="${DECK_WS_PORT:-8080}"
DECK_WS_URI="${DECK_WS_URI:-ws://127.0.0.1:$DECK_WS_PORT}"

run_flutter() {
  if command -v fvm >/dev/null 2>&1; then
    fvm flutter "$@"
    return
  fi

  flutter "$@"
}

case "$BUILD_MODE" in
  debug)
    PRODUCTS_CONFIGURATION="Debug"
    ENTITLEMENTS_FILE="$ROOT_DIR/macos/Runner/DebugProfile.entitlements"
    ;;
  profile)
    PRODUCTS_CONFIGURATION="Profile"
    ENTITLEMENTS_FILE="$ROOT_DIR/macos/Runner/DebugProfile.entitlements"
    ;;
  release)
    PRODUCTS_CONFIGURATION="Release"
    ENTITLEMENTS_FILE="$ROOT_DIR/macos/Runner/Release.entitlements"
    ;;
  *)
    echo "Unsupported BUILD_MODE: $BUILD_MODE" >&2
    echo "Use debug, profile, or release." >&2
    exit 64
    ;;
esac

set_plist_string() {
  local plist="$1"
  local key="$2"
  local value="$3"

  if /usr/libexec/PlistBuddy -c "Print :$key" "$plist" >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c "Set :$key $value" "$plist"
  else
    /usr/libexec/PlistBuddy -c "Add :$key string $value" "$plist"
  fi
}

build_app() {
  local target="$1"
  local app_name="$2"
  local bundle_identifier="$3"
  local destination="$DIST_DIR/$app_name.app"
  local products_dir="$ROOT_DIR/build/macos/Build/Products/$PRODUCTS_CONFIGURATION"

  echo
  echo "Building $app_name from $target..."

  run_flutter build macos \
    "--$BUILD_MODE" \
    "--target=$target" \
    "--dart-define=DECK_WS_URI=$DECK_WS_URI"

  local source_app
  source_app="$(find "$products_dir" -maxdepth 1 -type d -name '*.app' -print -quit)"

  if [[ -z "$source_app" ]]; then
    echo "No .app bundle found in $products_dir" >&2
    exit 1
  fi

  rm -rf "$destination"
  ditto "$source_app" "$destination"

  local plist="$destination/Contents/Info.plist"
  set_plist_string "$plist" CFBundleIdentifier "$bundle_identifier"
  set_plist_string "$plist" CFBundleName "$app_name"
  set_plist_string "$plist" CFBundleDisplayName "$app_name"

  xattr -cr "$destination"
  codesign \
    --force \
    --deep \
    --sign - \
    --entitlements "$ENTITLEMENTS_FILE" \
    "$destination"

  echo "Created: $destination"
}

cd "$ROOT_DIR"
mkdir -p "$DIST_DIR"

run_flutter pub get

build_app \
  lib/main.dart \
  "Scout Projector" \
  net.fenixsoftware.scoutPresentationGenerator.projector

build_app \
  lib/main_presenter.dart \
  "Scout Presenter" \
  net.fenixsoftware.scoutPresentationGenerator.presenter

cat <<EOF_MESSAGE

Both macOS applications are ready:
  $DIST_DIR/Scout Projector.app
  $DIST_DIR/Scout Presenter.app

WebSocket endpoint:
  $DECK_WS_URI
EOF_MESSAGE
