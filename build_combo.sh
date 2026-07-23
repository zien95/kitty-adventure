#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

APP_NAME="$(awk '/^name:/ {print $2; exit}' pubspec.yaml)"
APP_VERSION="$(awk '/^version:/ {print $2; exit}' pubspec.yaml)"
APP_SLUG="${APP_NAME//_/-}"
VERSION_SLUG="${APP_VERSION//+/-}"
OUTPUT_DIR="$PROJECT_DIR/build/combo"
IPA_TMP_DIR=""
CLEAN_FIRST="${CLEAN_FIRST:-1}"
MIN_FREE_GB="${MIN_FREE_GB:-10}"
RESUME_BUILD="${RESUME_BUILD:-0}"
SKIP_MACOS="${SKIP_MACOS:-0}"
SKIP_ANDROID="${SKIP_ANDROID:-0}"
SKIP_WEB="${SKIP_WEB:-0}"
SKIP_IOS="${SKIP_IOS:-0}"
# Keep an empty sentinel at index 0 so Bash 3.2 can safely expand the optional
# arguments under `set -u`. Every build command skips that sentinel.
FLUTTER_BUILD_ARGS=("")

if [[ -n "${KITTY_UPDATE_MANIFEST_URL:-}" ]]; then
  FLUTTER_BUILD_ARGS+=(
    "--dart-define=KITTY_UPDATE_MANIFEST_URL=$KITTY_UPDATE_MANIFEST_URL"
  )
fi

if [[ -n "${KITTY_UPDATE_PUBLIC_IP:-}" ]]; then
  FLUTTER_BUILD_ARGS+=(
    "--dart-define=KITTY_UPDATE_PUBLIC_IP=$KITTY_UPDATE_PUBLIC_IP"
  )
fi

cleanup() {
  if [[ -n "$IPA_TMP_DIR" && -d "$IPA_TMP_DIR" ]]; then
    rm -rf "$IPA_TMP_DIR"
  fi
}
trap cleanup EXIT

log() {
  printf '\n==> %s\n' "$1"
}

fail() {
  printf '\nERROR: %s\n' "$1" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "$1 is not installed or not in PATH."
}

remove_path() {
  local path="$1"
  if [[ -e "$path" ]]; then
    rm -rf "$path"
  fi
}

clean_generated_builds() {
  if [[ "$RESUME_BUILD" == "1" ]]; then
    log "Resuming existing build combo output"
    mkdir -p "$OUTPUT_DIR"
    return
  fi

  if [[ "$CLEAN_FIRST" == "1" ]]; then
    log "Cleaning old generated Flutter builds"
    flutter clean
  fi

  rm -rf "$OUTPUT_DIR"
  mkdir -p "$OUTPUT_DIR"
}

check_disk_space() {
  local free_kb
  local required_kb

  free_kb="$(df -Pk "$PROJECT_DIR" | awk 'NR == 2 {print $4}')"
  required_kb=$((MIN_FREE_GB * 1024 * 1024))

  if ((free_kb < required_kb)); then
    fail "Not enough free disk space. Need at least ${MIN_FREE_GB}GB free for the full build combo; current free space is about $((free_kb / 1024))MB."
  fi
}

build_macos() {
  log "Building macOS"
  PATH="$PROJECT_DIR/tools/bin:$PATH" \
    flutter build macos --release --no-tree-shake-icons \
    "${FLUTTER_BUILD_ARGS[@]:1}"

  local release_dir="build/macos/Build/Products/Release"
  local app_bundle
  local app_output
  local dmg_output
  app_bundle="$(find "$release_dir" -maxdepth 1 -type d -name '*.app' | head -n 1)"

  [[ -n "$app_bundle" && -d "$app_bundle" ]] || fail "macOS .app bundle was not found in $release_dir."

  mkdir -p "$OUTPUT_DIR/macos"
  app_output="$OUTPUT_DIR/macos/$(basename "$app_bundle")"
  dmg_output="$OUTPUT_DIR/macos/${APP_SLUG}-macos-v${VERSION_SLUG}.dmg"
  rm -rf "$app_output"
  rm -f "$dmg_output"
  cp -R "$app_bundle" "$app_output"
  hdiutil create \
    -volname "Kitty Adventure" \
    -srcfolder "$app_output" \
    -ov \
    -format UDZO \
    "$dmg_output"

  printf 'macOS app: %s\n' "$app_output"
  printf 'macOS DMG: %s\n' "$dmg_output"
  remove_path "$PROJECT_DIR/build/macos"
}

build_android() {
  log "Building Android APK"
  flutter build apk --release --no-tree-shake-icons \
    "${FLUTTER_BUILD_ARGS[@]:1}"

  local apk_source="build/app/outputs/flutter-apk/app-release.apk"
  local apk_output="$OUTPUT_DIR/android/${APP_SLUG}-v${VERSION_SLUG}.apk"

  [[ -f "$apk_source" ]] || fail "Android APK was not found at $apk_source."

  mkdir -p "$OUTPUT_DIR/android"
  cp "$apk_source" "$apk_output"

  printf 'Android APK: %s\n' "$apk_output"
  find "$PROJECT_DIR/build" -mindepth 1 -maxdepth 1 ! -name combo -exec rm -rf {} +
}

build_web() {
  log "Building Web"
  flutter build web --release --no-tree-shake-icons --no-wasm-dry-run \
    --base-href / \
    "${FLUTTER_BUILD_ARGS[@]:1}"

  local web_output="$OUTPUT_DIR/web"
  local web_zip="$OUTPUT_DIR/${APP_SLUG}-web-v${VERSION_SLUG}.zip"

  [[ -d "build/web" ]] || fail "Web build directory was not found at build/web."

  rm -rf "$web_output"
  mkdir -p "$web_output"
  cp -R build/web/. "$web_output/"

  rm -f "$web_zip"
  (cd "$web_output" && zip -qry "$web_zip" .)

  printf 'Web files: %s\n' "$web_output"
  printf 'Web zip: %s\n' "$web_zip"
  remove_path "$PROJECT_DIR/build/web"
}

build_sideloadly_ipa() {
  log "Building unsigned iOS app for Sideloadly"
  flutter build ios --release --no-codesign --no-tree-shake-icons \
    "${FLUTTER_BUILD_ARGS[@]:1}"

  local ios_app="build/ios/iphoneos/Runner.app"
  local ipa_output="$OUTPUT_DIR/ios/${APP_SLUG}-Sideloadly-v${VERSION_SLUG}.ipa"

  [[ -d "$ios_app" ]] || fail "iOS Runner.app was not found at $ios_app."

  mkdir -p "$OUTPUT_DIR/ios"
  rm -f "$ipa_output"

  IPA_TMP_DIR="$(mktemp -d)"
  mkdir -p "$IPA_TMP_DIR/Payload"
  cp -R "$ios_app" "$IPA_TMP_DIR/Payload/"

  (cd "$IPA_TMP_DIR" && zip -qry "$ipa_output" Payload)

  printf 'Sideloadly IPA: %s\n' "$ipa_output"
  remove_path "$PROJECT_DIR/build/ios"
}

write_build_info() {
  local build_info="$OUTPUT_DIR/BUILD_INFO.txt"

  cat > "$build_info" <<EOF
Build Combo
===========
App: $APP_NAME
Version: $APP_VERSION
Built at: $(date '+%Y-%m-%d %H:%M:%S')
Flutter: $(flutter --version | head -n 1)

Outputs:
- macOS app: $OUTPUT_DIR/macos
- macOS DMG: $OUTPUT_DIR/macos/${APP_SLUG}-macos-v${VERSION_SLUG}.dmg
- Android APK: $OUTPUT_DIR/android/${APP_SLUG}-v${VERSION_SLUG}.apk
- Web files: $OUTPUT_DIR/web
- Web zip: $OUTPUT_DIR/${APP_SLUG}-web-v${VERSION_SLUG}.zip
- Sideloadly IPA: $OUTPUT_DIR/ios/${APP_SLUG}-Sideloadly-v${VERSION_SLUG}.ipa

Sideloadly:
1. Open Sideloadly.
2. Connect your iPhone or iPad.
3. Drag in the IPA from the path above.
4. Sign/install with your Apple ID.
EOF

  printf 'Build info: %s\n' "$build_info"
}

main() {
  [[ -f "pubspec.yaml" ]] || fail "Run this script from the Flutter project root."
  require_command flutter
  require_command hdiutil
  require_command zip

  log "Preparing build combo for $APP_NAME v$APP_VERSION"
  clean_generated_builds

  flutter pub get
  check_disk_space

  [[ "$SKIP_MACOS" == "1" ]] || build_macos
  [[ "$SKIP_ANDROID" == "1" ]] || build_android
  [[ "$SKIP_WEB" == "1" ]] || build_web
  [[ "$SKIP_IOS" == "1" ]] || build_sideloadly_ipa
  write_build_info

  log "Build combo complete"
  find "$OUTPUT_DIR" -maxdepth 3 -type f -print
}

main "$@"
