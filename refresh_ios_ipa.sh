#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEAM_ID="${IOS_TEAM_ID:-9JZ8BU782J}"
BUNDLE_ID="com.example.tryingToRestorePup"
VERSION="$(
  sed -n 's/^version:[[:space:]]*//p' "$PROJECT_DIR/pubspec.yaml" | head -1
)"
ARCHIVE_PATH="$PROJECT_DIR/build/ios/archive/Runner.xcarchive"
EXPORT_DIR="$PROJECT_DIR/build/ios/xcode-export"
EXPORT_OPTIONS="$PROJECT_DIR/build/ios/xcode-export-options.plist"
ARCHIVE_LOG="$PROJECT_DIR/build/ios/xcode-refresh-archive.log"
EXPORT_LOG="$PROJECT_DIR/build/ios/xcode-refresh-export.log"
DOWNLOAD_IPA="$HOME/Downloads/kitty-adventure-Xcode-signed-v${VERSION}.ipa"

log() {
  printf '\n==> %s\n' "$1"
}

fail() {
  printf '\nERROR: %s\n' "$1" >&2
  exit 1
}

explain_xcode_failure() {
  local log_file="$1"

  if grep -q "No Accounts" "$log_file"; then
    cat >&2 <<'EOF'

Xcode says no Apple account is signed in.

Open Xcode, then go to:
  Xcode > Settings > Accounts

Add your Apple ID, then open:
  ios/Runner.xcworkspace

Click Runner > Signing & Capabilities, pick your team, keep the iPad connected,
and let Xcode create the new provisioning profile. Then run this script again.
EOF
  elif grep -q "No profiles for" "$log_file"; then
    cat >&2 <<EOF

Xcode could not make a provisioning profile for:
  $BUNDLE_ID

Open ios/Runner.xcworkspace in Xcode, select Runner > Signing & Capabilities,
choose your team, connect/unlock the iPad, and let Xcode repair signing.
Then run this script again.
EOF
  fi
}

require_command() {
  command -v "$1" >/dev/null 2>&1 ||
    fail "$1 is required."
}

require_command flutter
require_command xcodebuild
require_command plutil
require_command security

cd "$PROJECT_DIR"
mkdir -p "$PROJECT_DIR/build/ios"

log "Getting Flutter packages"
flutter pub get

if command -v pod >/dev/null 2>&1; then
  log "Refreshing CocoaPods"
  (cd ios && pod install)
fi

log "Writing export options for team $TEAM_ID"
cat >"$EXPORT_OPTIONS" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>development</string>
  <key>teamID</key>
  <string>$TEAM_ID</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>destination</key>
  <string>export</string>
  <key>compileBitcode</key>
  <false/>
  <key>stripSwiftSymbols</key>
  <true/>
  <key>uploadSymbols</key>
  <false/>
</dict>
</plist>
EOF

log "Archiving iOS app"
rm -rf "$ARCHIVE_PATH" "$EXPORT_DIR"
if ! xcodebuild \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -destination generic/platform=iOS \
  -archivePath "$ARCHIVE_PATH" \
  -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  archive >"$ARCHIVE_LOG" 2>&1; then
  tail -80 "$ARCHIVE_LOG" >&2
  explain_xcode_failure "$ARCHIVE_LOG"
  fail "Archive failed. Full log: $ARCHIVE_LOG"
fi

log "Exporting signed IPA"
if ! xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS" \
  -exportPath "$EXPORT_DIR" \
  -allowProvisioningUpdates \
  >"$EXPORT_LOG" 2>&1; then
  tail -80 "$EXPORT_LOG" >&2
  explain_xcode_failure "$EXPORT_LOG"
  fail "Export failed. Full log: $EXPORT_LOG"
fi

IPA_PATH="$(find "$EXPORT_DIR" -maxdepth 1 -type f -name '*.ipa' -print -quit)"
[[ -n "$IPA_PATH" ]] || fail "Xcode export finished, but no IPA was created."

cp "$IPA_PATH" "$DOWNLOAD_IPA"

log "Verifying embedded provisioning profile"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
ditto -x -k "$DOWNLOAD_IPA" "$TMP_DIR"
PROFILE="$(find "$TMP_DIR/Payload" -name embedded.mobileprovision -print -quit)"
[[ -n "$PROFILE" ]] || fail "The exported IPA has no embedded provisioning profile."
PROFILE_PLIST="$TMP_DIR/profile.plist"
security cms -D -i "$PROFILE" >"$PROFILE_PLIST"
EXPIRATION="$(plutil -extract ExpirationDate raw -o - "$PROFILE_PLIST")"

printf '\nFresh signed IPA:\n'
printf '  %s\n' "$DOWNLOAD_IPA"
printf 'Provisioning profile expires:\n'
printf '  %s\n' "$EXPIRATION"
printf '\nInstall it with:\n'
printf '  ./install_ios.sh "%s"\n' "$DOWNLOAD_IPA"
