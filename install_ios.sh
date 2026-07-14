#!/usr/bin/env bash
set -Eeuo  

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IPA_ARGUMENT="${1:-}"
LIST_ONLY=0
WORK_DIR=""

DEVICE_IDS=()
DEVICE_NAMES=()
DEVICE_MODELS=()
DEVICE_UDIDS=()
DEVICE_CONNECTIONS=()
DEVICE_STATUSES=()

case "$IPA_ARGUMENT" in
  --list-devices | --devices)
    LIST_ONLY=1
    IPA_ARGUMENT=""
    ;;
esac

cleanup() {
  if [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]]; then
    rm -rf "$WORK_DIR"
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
  command -v "$1" >/dev/null 2>&1 ||
    fail "$1 is required. Install Xcode and its command-line tools first."
}

connection_label() {
  case "$1" in
    localNetwork)
      printf 'Wi-Fi'
      ;;
    usb | USB | wired)
      printf 'USB'
      ;;
    *)
      printf '%s' "${1:-USB or Wi-Fi}"
      ;;
  esac
}

discover_devices() {
  local json_file
  json_file="$(mktemp)"

  if ! xcrun devicectl list devices \
    --json-output "$json_file" >/dev/null; then
    rm -f "$json_file"
    fail "Xcode could not list paired devices."
  fi

  while IFS=$'\t' read -r identifier name model udid transport pairing tunnel; do
    [[ -n "$identifier" ]] || continue
    DEVICE_IDS+=("$identifier")
    DEVICE_NAMES+=("$name")
    DEVICE_MODELS+=("$model")
    DEVICE_UDIDS+=("$udid")
    DEVICE_CONNECTIONS+=("$(connection_label "$transport")")
    DEVICE_STATUSES+=("${pairing:-paired}, tunnel ${tunnel:-unknown}")
  done < <(
    jq -r '
      .result.devices[]
      | select(.hardwareProperties.platform == "iOS")
      | select(.hardwareProperties.reality == "physical")
      | select((.connectionProperties.pairingState // "") == "paired")
      | [
          .identifier,
          .deviceProperties.name,
          .hardwareProperties.marketingName,
          .hardwareProperties.udid,
          (.connectionProperties.transportType // "USB or Wi-Fi"),
          (.connectionProperties.pairingState // "paired"),
          (.connectionProperties.tunnelState // "unknown")
        ]
      | @tsv
    ' "$json_file"
  )

  rm -f "$json_file"

  if ((${#DEVICE_IDS[@]} == 0)); then
    fail "No paired iPhone or iPad was found. Connect by USB, unlock the device, trust this Mac, and enable Developer Mode."
  fi
}

print_devices() {
  local index

  printf '\nAvailable iPhone and iPad devices:\n\n'
  for ((index = 0; index < ${#DEVICE_IDS[@]}; index++)); do
    printf '  %d) %s\n' "$((index + 1))" "${DEVICE_NAMES[$index]}"
    printf '     %s | %s | %s | %s\n' \
      "${DEVICE_MODELS[$index]}" \
      "${DEVICE_CONNECTIONS[$index]}" \
      "${DEVICE_UDIDS[$index]}" \
      "${DEVICE_STATUSES[$index]}"
  done
}

choose_device() {
  local choice

  print_devices

  while true; do
    printf '\nWhich device should receive the app? [1-%d]: ' "${#DEVICE_IDS[@]}"
    if ! read -r choice; then
      fail "No device was selected."
    fi

    if [[ "$choice" =~ ^[0-9]+$ ]] &&
      ((choice >= 1 && choice <= ${#DEVICE_IDS[@]})); then
      SELECTED_INDEX=$((choice - 1))
      return
    fi

    printf 'Please enter a number from 1 to %d.\n' "${#DEVICE_IDS[@]}"
  done
}

find_default_ipa() {
  local candidates=()
  local file

  while IFS= read -r file; do
    candidates+=("$file")
  done < <(
    find \
      "$HOME/Downloads" \
      "$PROJECT_DIR/build/combo/ios" \
      -maxdepth 1 \
      -type f \
      -name '*.ipa' \
      -print 2>/dev/null |
      while IFS= read -r file; do
        printf '%s\t%s\n' "$(stat -f '%m' "$file")" "$file"
      done |
      sort -rn |
      cut -f2-
  )

  if ((${#candidates[@]} > 0)); then
    printf '%s' "${candidates[0]}"
  fi
}

choose_ipa() {
  local default_ipa
  local entered_path

  if [[ -n "$IPA_ARGUMENT" ]]; then
    IPA_PATH="$IPA_ARGUMENT"
  else
    default_ipa="$(find_default_ipa)"

    if [[ -n "$default_ipa" ]]; then
      printf '\nIPA file [%s]: ' "$default_ipa"
    else
      printf '\nIPA file path: '
    fi

    read -r entered_path
    IPA_PATH="${entered_path:-$default_ipa}"
  fi

  IPA_PATH="${IPA_PATH/#\~/$HOME}"
  [[ -n "$IPA_PATH" ]] || fail "No IPA was selected."
  [[ -f "$IPA_PATH" ]] || fail "IPA not found: $IPA_PATH"
  [[ "$IPA_PATH" == *.ipa ]] || fail "Selected file is not an .ipa: $IPA_PATH"
}

extract_and_verify_ipa() {
  local apps=()
  local app

  WORK_DIR="$(mktemp -d)"
  ditto -x -k "$IPA_PATH" "$WORK_DIR" ||
    fail "The IPA could not be extracted."

  while IFS= read -r app; do
    apps+=("$app")
  done < <(find "$WORK_DIR/Payload" -maxdepth 1 -type d -name '*.app' -print)

  if ((${#apps[@]} != 1)); then
    fail "The IPA must contain exactly one app inside Payload."
  fi

  APP_PATH="${apps[0]}"
  codesign --verify --deep --strict "$APP_PATH" ||
    fail "The app's code signature is invalid."

  APP_NAME="$(
    plutil -extract CFBundleDisplayName raw -o - "$APP_PATH/Info.plist" \
      2>/dev/null ||
      plutil -extract CFBundleName raw -o - "$APP_PATH/Info.plist"
  )"
  BUNDLE_ID="$(
    plutil -extract CFBundleIdentifier raw -o - "$APP_PATH/Info.plist"
  )"
  APP_VERSION="$(
    plutil -extract CFBundleShortVersionString raw -o - "$APP_PATH/Info.plist"
  )"
}

verify_device_profile() {
  local profile="$APP_PATH/embedded.mobileprovision"
  local profile_plist
  local profile_expiration
  local profile_expiration_epoch
  local now_epoch
  local provisioned_devices
  local selected_udid="${DEVICE_UDIDS[$SELECTED_INDEX]}"

  [[ -f "$profile" ]] ||
    fail "The IPA has no embedded provisioning profile."

  profile_plist="$(mktemp)"
  security cms -D -i "$profile" >"$profile_plist" 2>/dev/null ||
    fail "The IPA's provisioning profile could not be read."

  profile_expiration="$(
    plutil -extract ExpirationDate raw -o - "$profile_plist" 2>/dev/null || true
  )"
  if [[ -n "$profile_expiration" ]]; then
    profile_expiration_epoch="$(
      date -j -u -f '%Y-%m-%dT%H:%M:%SZ' "$profile_expiration" '+%s' \
        2>/dev/null || true
    )"
    now_epoch="$(date -u '+%s')"
    if [[ -n "$profile_expiration_epoch" ]] &&
      ((profile_expiration_epoch <= now_epoch)); then
      rm -f "$profile_plist"
      fail "This IPA's provisioning profile expired on $profile_expiration. Add your Apple ID in Xcode if needed, run ./refresh_ios_ipa.sh, then install the fresh IPA."
    fi
  fi

  if plutil -extract ProvisionedDevices raw -o - "$profile_plist" \
    >/dev/null 2>&1; then
    provisioned_devices="$(
      plutil -extract ProvisionedDevices xml1 -o - "$profile_plist"
    )"
    if ! grep -Fq "<string>$selected_udid</string>" \
      <<<"$provisioned_devices"; then
      rm -f "$profile_plist"
      fail "This IPA is not signed for ${DEVICE_NAMES[$SELECTED_INDEX]} ($selected_udid). Connect it in Xcode once, rebuild, and run this installer again."
    fi
  fi

  rm -f "$profile_plist"
}

install_app() {
  local device_id="${DEVICE_IDS[$SELECTED_INDEX]}"

  log "Installing $APP_NAME v$APP_VERSION on ${DEVICE_NAMES[$SELECTED_INDEX]}"
  if ! xcrun devicectl device install app \
    --device "$device_id" \
    "$APP_PATH"; then
    printf '\nInstallation failed. Check that the device is unlocked, has enough free storage,\n' >&2
    printf 'trusts this developer, and is included in the provisioning profile.\n' >&2
    exit 1
  fi

  printf '\nInstalled successfully:\n'
  printf '  App: %s v%s\n' "$APP_NAME" "$APP_VERSION"
  printf '  Bundle: %s\n' "$BUNDLE_ID"
  printf '  Device: %s (%s)\n' \
    "${DEVICE_NAMES[$SELECTED_INDEX]}" \
    "${DEVICE_CONNECTIONS[$SELECTED_INDEX]}"
}

offer_launch() {
  local answer

  printf '\nLaunch the app now? [Y/n]: '
  read -r answer
  case "$answer" in
    n | N | no | NO)
      return
      ;;
  esac

  log "Launching $APP_NAME"
  if ! xcrun devicectl device process launch \
    --device "${DEVICE_IDS[$SELECTED_INDEX]}" \
    --terminate-existing \
    "$BUNDLE_ID"; then
    printf '\nThe app installed, but Apple blocked the launch.\n' >&2
    printf 'Unlock the device and trust the developer in:\n' >&2
    printf 'Settings > General > VPN & Device Management\n' >&2
    exit 1
  fi
}

main() {
  require_command xcrun
  require_command jq
  require_command ditto
  require_command codesign
  require_command plutil

  log "Looking for paired iPhone and iPad devices"
  discover_devices
  if ((LIST_ONLY)); then
    print_devices
    log "Device check complete"
    return
  fi
  choose_device
  choose_ipa
  extract_and_verify_ipa
  verify_device_profile
  install_app
  offer_launch

  log "Done"
}

main "$@"
