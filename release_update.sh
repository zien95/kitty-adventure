#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

INFO_FILE="$PROJECT_DIR/UPDATE_SERVER_INFO.txt"
VERSION="${1:-}"
if (($# > 0)); then
  shift
fi
CHANGELOG=("$@")
REQUIRED_UPDATE="${REQUIRED_UPDATE:-}"
SKIP_BUILD="${SKIP_BUILD:-}"
PUBLIC_GAME_URL="${KITTY_PUBLIC_GAME_URL:-https://kitty-adventure-zona.web.app}"
INDEXNOW_KEY="${KITTY_INDEXNOW_KEY:-7814c885d95d04f5e4dad44845b8240c}"

log() {
  printf '\n==> %s\n' "$1"
}

fail() {
  printf '\nERROR: %s\n' "$1" >&2
  exit 1
}

read_info_value() {
  local key="$1"
  awk -F= -v key="$key" '$1 == key {sub(/^[^=]*=/, ""); print; exit}' "$INFO_FILE"
}

next_patch_version() {
  python3 - "$1" <<'PY'
import sys

version = sys.argv[1].split("+", 1)[0]
parts = [int(part) for part in version.split(".")]
parts[-1] += 1
print(".".join(str(part) for part in parts))
PY
}

ask_yes_no() {
  local prompt="$1"
  local default_answer="$2"
  local answer

  if [[ "$default_answer" == "yes" ]]; then
    read -r -p "$prompt [Y/n]: " answer
    answer="${answer:-y}"
  else
    read -r -p "$prompt [y/N]: " answer
    answer="${answer:-n}"
  fi

  [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]
}

collect_release_details() {
  local current_version suggested_version item
  current_version="$(awk '/^version:/ {print $2; exit}' pubspec.yaml)"
  suggested_version="$(next_patch_version "$current_version")"

  if [[ -z "$VERSION" ]]; then
    printf 'Current version: %s\n' "$current_version"
    read -r -p "New version [$suggested_version]: " VERSION
    VERSION="${VERSION:-$suggested_version}"
  fi

  if [[ -z "$REQUIRED_UPDATE" ]]; then
    if ask_yes_no "Must players install this update before continuing?" "no"; then
      REQUIRED_UPDATE="true"
    else
      REQUIRED_UPDATE="false"
    fi
  fi

  if ((${#CHANGELOG[@]} == 0)); then
    printf '\nEnter changelog items one at a time.\n'
    printf 'Press Return on an empty item when finished.\n'
    while true; do
      read -r -p "Changelog item: " item
      [[ -n "$item" ]] || break
      CHANGELOG+=("$item")
    done
  fi

  if ((${#CHANGELOG[@]} == 0)); then
    CHANGELOG=("Bug fixes")
  fi

  if [[ -z "$SKIP_BUILD" ]]; then
    if ask_yes_no "Build every platform and publish now?" "yes"; then
      SKIP_BUILD="0"
    else
      SKIP_BUILD="1"
    fi
  fi

  printf '\nRelease summary\n'
  printf 'Version: %s\n' "$VERSION"
  printf 'Required: %s\n' "$REQUIRED_UPDATE"
  printf 'Build all platforms: %s\n' \
    "$([[ "$SKIP_BUILD" == "1" ]] && printf 'no' || printf 'yes')"
  printf 'Changelog:\n'
  printf '  - %s\n' "${CHANGELOG[@]}"

  ask_yes_no "Continue with this release?" "yes" ||
    fail "Release cancelled."
}

validate_version() {
  [[ "$VERSION" =~ ^[0-9]+(\.[0-9]+){2}([+][0-9]+)?$ ]] ||
    fail "Use a version like 26.8.2 or 26.8.2+1."
}

bump_app_version() {
  log "Updating app version to $VERSION"
  python3 - "$VERSION" "$PROJECT_DIR" <<'PY'
from pathlib import Path
import re
import sys

version = sys.argv[1]
project = Path(sys.argv[2])

pubspec = project / "pubspec.yaml"
pubspec_text = pubspec.read_text()
pubspec_text, pubspec_count = re.subn(
    r"(?m)^version:\s*\S+\s*$",
    f"version: {version}",
    pubspec_text,
    count=1,
)
if pubspec_count != 1:
    raise SystemExit("Could not update pubspec.yaml version.")
pubspec.write_text(pubspec_text)

service = project / "lib/services/update_service.dart"
service_text = service.read_text()
service_text, service_count = re.subn(
    r"static const String currentVersion = '[^']+';",
    f"static const String currentVersion = '{version.split('+', 1)[0]}';",
    service_text,
    count=1,
)
if service_count != 1:
    raise SystemExit("Could not update UpdateService.currentVersion.")
service.write_text(service_text)

downloads_page = project / "web/files/index.html"
downloads_text = downloads_page.read_text()
public_version = version.split("+", 1)[0]
downloads_text = re.sub(
    r"v\d+\.\d+\.\d+",
    f"v{public_version}",
    downloads_text,
)
downloads_page.write_text(downloads_text)
PY

  dart format "$PROJECT_DIR/lib/services/update_service.dart" >/dev/null
}

build_release_files() {
  if [[ "$SKIP_BUILD" == "1" ]]; then
    log "Skipping builds because SKIP_BUILD=1"
    return
  fi

  log "Building macOS, Android, web, and Sideloadly IPA"
  KITTY_UPDATE_MANIFEST_URL="$MANIFEST_URL" \
    KITTY_UPDATE_PUBLIC_IP="$PUBLIC_IP" \
    "$PROJECT_DIR/build_combo.sh"
}

copy_release_files() {
  local app_name app_slug version_slug output_dir
  local apk_source ipa_source web_zip_source mac_app mac_zip_name

  app_name="$(awk '/^name:/ {print $2; exit}' "$PROJECT_DIR/pubspec.yaml")"
  app_slug="${app_name//_/-}"
  version_slug="${VERSION//+/-}"
  output_dir="$PROJECT_DIR/build/combo"

  apk_source="$output_dir/android/${app_slug}-v${version_slug}.apk"
  ipa_source="$output_dir/ios/${app_slug}-Sideloadly-v${version_slug}.ipa"
  web_zip_source="$output_dir/${app_slug}-web-v${version_slug}.zip"
  mac_app=""
  if [[ -d "$output_dir/macos" ]]; then
    mac_app="$(
      find "$output_dir/macos" -maxdepth 1 -type d -name '*.app' |
        head -n 1
    )"
  fi

  [[ -f "$apk_source" ]] || fail "Missing Android build: $apk_source"
  [[ -f "$ipa_source" ]] || fail "Missing IPA build: $ipa_source"
  [[ -f "$web_zip_source" ]] || fail "Missing web zip: $web_zip_source"
  [[ -d "$output_dir/web" ]] || fail "Missing web build: $output_dir/web"
  [[ -n "$mac_app" && -d "$mac_app" ]] || fail "Missing macOS .app build."

  mkdir -p "$UPDATE_DIR/files" "$UPDATE_DIR/web"
  rm -rf "$UPDATE_DIR/web"
  mkdir -p "$UPDATE_DIR/web"
  cp -R "$output_dir/web/." "$UPDATE_DIR/web/"
  cp -R "$output_dir/web/." "$UPDATE_DIR/"

  APK_NAME="${app_slug}-v${version_slug}.apk"
  IPA_NAME="${app_slug}-Sideloadly-v${version_slug}.ipa"
  WEB_ZIP_NAME="${app_slug}-web-v${version_slug}.zip"
  mac_zip_name="${app_slug}-macos-v${version_slug}.zip"
  MACOS_ZIP_NAME="$mac_zip_name"

  cp "$apk_source" "$UPDATE_DIR/files/$APK_NAME"
  cp "$ipa_source" "$UPDATE_DIR/files/$IPA_NAME"
  cp "$web_zip_source" "$UPDATE_DIR/files/$WEB_ZIP_NAME"

  rm -f "$UPDATE_DIR/files/$MACOS_ZIP_NAME"
  if command -v ditto >/dev/null 2>&1; then
    ditto -c -k --sequesterRsrc --keepParent \
      "$mac_app" \
      "$UPDATE_DIR/files/$MACOS_ZIP_NAME"
  else
    (
      cd "$(dirname "$mac_app")"
      zip -qry "$UPDATE_DIR/files/$MACOS_ZIP_NAME" "$(basename "$mac_app")"
    )
  fi
}

write_manifest() {
  local changelog_file
  changelog_file="$(mktemp)"

  if ((${#CHANGELOG[@]} == 0)); then
    CHANGELOG=("Bug fixes")
  fi

  printf '%s\n' "${CHANGELOG[@]}" >"$changelog_file"

  export VERSION REQUIRED_UPDATE BASE_URL UPDATE_DIR PUBLIC_GAME_URL
  export APK_NAME IPA_NAME WEB_ZIP_NAME MACOS_ZIP_NAME
  export CHANGELOG_FILE="$changelog_file"

  python3 <<'PY'
from datetime import date
from pathlib import Path
import json
import os

base = os.environ["BASE_URL"].rstrip("/")
update_dir = Path(os.environ["UPDATE_DIR"])
version = os.environ["VERSION"].split("+", 1)[0]
changelog = [
    line.strip()
    for line in Path(os.environ["CHANGELOG_FILE"]).read_text().splitlines()
    if line.strip()
]

manifest = {
    "app": "Kitty Adventure",
    "version": version,
    "title": f"Kitty Adventure v{version}",
    "required": os.environ["REQUIRED_UPDATE"].lower() == "true",
    "release_date": date.today().isoformat(),
    "size": "See download",
    "changelog": changelog or ["Bug fixes"],
    "download_url": f"{base}/files/{os.environ['WEB_ZIP_NAME']}",
    "web_url": os.environ["PUBLIC_GAME_URL"].rstrip("/") + "/",
    "apk_url": f"{base}/files/{os.environ['APK_NAME']}",
    "ipa_url": f"{base}/files/{os.environ['IPA_NAME']}",
    "macos_url": f"{base}/files/{os.environ['MACOS_ZIP_NAME']}",
}

payload = json.dumps(manifest, indent=2) + "\n"
(update_dir / "latest.json").write_text(payload)
Path("updates/latest.json").write_text(payload)
PY

  rm -f "$changelog_file"
}

deploy_public_game() {
  local combo_web="$PROJECT_DIR/build/combo/web"

  if [[ "$SKIP_BUILD" == "1" && ! -d "$combo_web" ]]; then
    log "Skipping Firebase Hosting deploy because the web build was skipped and no combo web output exists"
    return
  fi

  if ! command -v firebase >/dev/null 2>&1; then
    log "Warning: Firebase CLI is missing; the update files are live, but the public web game was not deployed"
    return
  fi

  if [[ -d "$combo_web" ]]; then
    rm -rf "$PROJECT_DIR/build/web"
    mkdir -p "$PROJECT_DIR/build/web"
    cp -R "$combo_web/." "$PROJECT_DIR/build/web/"
  fi

  log "Publishing the searchable web game"
  firebase deploy --only hosting --project kitty-adventure-zona
}

notify_search_engines() {
  local status

  log "Notifying Bing and IndexNow search engines"
  status="$(
    curl -sS -o /dev/null -w '%{http_code}' --max-time 30 \
      --get 'https://api.indexnow.org/indexnow' \
      --data-urlencode "url=${PUBLIC_GAME_URL%/}/" \
      --data-urlencode "key=$INDEXNOW_KEY"
  )"

  if [[ "$status" != "200" && "$status" != "202" ]]; then
    log "Warning: IndexNow returned HTTP $status"
    return
  fi

  printf 'IndexNow accepted the public game URL with HTTP %s.\n' "$status"
}

record_release() {
  local release_record="$UPDATE_DIR/LAST_RELEASE.txt"

  cat >"$release_record" <<EOF
Kitty Adventure Release
=======================
VERSION=$VERSION
RELEASED_AT=$(date '+%Y-%m-%dT%H:%M:%S%z')
MANIFEST_URL=$MANIFEST_URL
BASE_URL=$BASE_URL
MANIFEST_FILE=$UPDATE_DIR/latest.json
FILES_DIR=$UPDATE_DIR/files
WEB_DIR=$UPDATE_DIR/web
EOF

  cp "$release_record" "$PROJECT_DIR/LAST_UPDATE_RELEASE.txt"

  log "Release v$VERSION is live"
  printf 'Manifest: %s\n' "$MANIFEST_URL"
  printf 'Release record: %s\n' "$PROJECT_DIR/LAST_UPDATE_RELEASE.txt"
}

verify_release() {
  log "Verifying the published manifest"

  local published_version
  published_version="$(
    curl -fsS --max-time 15 "$MANIFEST_URL?released=$(date +%s)" |
      python3 -c 'import json, sys; print(json.load(sys.stdin)["version"])'
  )" || fail "Could not read the published manifest at $MANIFEST_URL."

  [[ "$published_version" == "${VERSION%%+*}" ]] ||
    fail "Published manifest says v$published_version instead of v${VERSION%%+*}."

  printf 'Published manifest verified at %s\n' "$MANIFEST_URL"
}

main() {
  collect_release_details
  validate_version
  [[ -f "$INFO_FILE" ]] ||
    fail "Run ./setup_update_server.sh first so $INFO_FILE exists."

  UPDATE_DIR="$(read_info_value UPDATE_DIR)"
  WORLDWIDE_READY="$(read_info_value WORLDWIDE_READY)"
  PUBLIC_BASE_URL="$(read_info_value PUBLIC_BASE_URL)"
  LAN_BASE_URL="$(read_info_value LAN_BASE_URL)"
  PUBLIC_IP="$(read_info_value PUBLIC_IP)"

  [[ -n "$UPDATE_DIR" ]] || fail "UPDATE_DIR is missing from $INFO_FILE."

  if [[ "$WORLDWIDE_READY" == "yes" && -n "$PUBLIC_BASE_URL" ]]; then
    BASE_URL="${PUBLIC_BASE_URL%/}"
  else
    BASE_URL="${LAN_BASE_URL%/}"
    log "Warning: worldwide URL is not ready; this release will use the LAN URL"
  fi

  MANIFEST_URL="$BASE_URL/latest.json"

  bump_app_version
  build_release_files
  copy_release_files
  deploy_public_game
  notify_search_engines
  write_manifest
  record_release
  verify_release
}

main "$@"
