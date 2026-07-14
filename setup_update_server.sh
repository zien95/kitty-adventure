#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPDATE_DIR="${UPDATE_DIR:-$HOME/KittyAdventureUpdates}"
PORT="${UPDATE_PORT:-8081}"
INFO_FILE="$PROJECT_DIR/UPDATE_SERVER_INFO.txt"
LABEL="com.kittyadventure.update-server"
AWAKE_LABEL="com.kittyadventure.update-awake"
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_FILE="$PLIST_DIR/$LABEL.plist"
AWAKE_PLIST_FILE="$PLIST_DIR/$AWAKE_LABEL.plist"
HELPER_LOG="$UPDATE_DIR/logs/helper.log"
COMMAND="${1:-start}"
TUNNEL_URL="${KITTY_TUNNEL_URL:-https://unstamped-revisit-underling.ngrok-free.dev}"

log() {
  printf '\n==> %s\n' "$1"
}

fail() {
  printf '\nERROR: %s\n' "$1" >&2
  exit 1
}

prepare_filesystem() {
  mkdir -p \
    "$UPDATE_DIR/files" \
    "$UPDATE_DIR/web" \
    "$UPDATE_DIR/logs" \
    "$UPDATE_DIR/run" \
    "$PLIST_DIR"

  if [[ ! -f "$UPDATE_DIR/latest.json" ]]; then
    cp "$PROJECT_DIR/updates/latest.json" "$UPDATE_DIR/latest.json"
  fi
}

install_ngrok() {
  if command -v ngrok >/dev/null 2>&1; then
    return
  fi

  command -v brew >/dev/null 2>&1 ||
    fail "Homebrew is required to install ngrok."

  log "Installing ngrok"
  brew install ngrok/ngrok/ngrok
}

check_ngrok_config() {
  ngrok config check >/dev/null 2>&1 ||
    fail "ngrok needs an authtoken. Run: ngrok config add-authtoken YOUR_TOKEN"
}

xml_escape() {
  printf '%s' "$1" |
    sed -e 's/&/\\&amp;/g' -e 's/</\\&lt;/g' -e 's/>/\\&gt;/g'
}

write_launch_agent() {
  local python_path ngrok_path
  local escaped_project escaped_update escaped_python escaped_ngrok
  local escaped_helper_log escaped_tunnel_url

  python_path="$(command -v python3)"
  ngrok_path="$(command -v ngrok)"
  escaped_project="$(xml_escape "$PROJECT_DIR")"
  escaped_update="$(xml_escape "$UPDATE_DIR")"
  escaped_python="$(xml_escape "$python_path")"
  escaped_ngrok="$(xml_escape "$ngrok_path")"
  escaped_helper_log="$(xml_escape "$HELPER_LOG")"
  escaped_tunnel_url="$(xml_escape "$TUNNEL_URL")"

  cat >"$PLIST_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$escaped_python</string>
    <string>$escaped_project/tools/update_server_helper.py</string>
    <string>--project-dir</string>
    <string>$escaped_project</string>
    <string>--directory</string>
    <string>$escaped_update</string>
    <string>--port</string>
    <string>$PORT</string>
    <string>--ngrok</string>
    <string>$escaped_ngrok</string>
    <string>--tunnel-url</string>
    <string>$escaped_tunnel_url</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>ThrottleInterval</key>
  <integer>5</integer>
  <key>ProcessType</key>
  <string>Background</string>
  <key>StandardOutPath</key>
  <string>$escaped_helper_log</string>
  <key>StandardErrorPath</key>
  <string>$escaped_helper_log</string>
</dict>
</plist>
EOF

  plutil -lint "$PLIST_FILE" >/dev/null
}

write_awake_agent() {
  cat >"$AWAKE_PLIST_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$AWAKE_LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/caffeinate</string>
    <string>-ims</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>ProcessType</key>
  <string>Background</string>
</dict>
</plist>
EOF

  plutil -lint "$AWAKE_PLIST_FILE" >/dev/null
}

unload_helper() {
  launchctl bootout "gui/$UID/$LABEL" >/dev/null 2>&1 || true
}

unload_awake_helper() {
  launchctl bootout "gui/$UID/$AWAKE_LABEL" >/dev/null 2>&1 || true
}

load_awake_helper() {
  unload_awake_helper
  launchctl bootstrap "gui/$UID" "$AWAKE_PLIST_FILE"
}

stop_stale_child() {
  local pid_file="$1"

  [[ -f "$pid_file" ]] || return 0

  local pid
  pid="$(cat "$pid_file" 2>/dev/null || true)"
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true
    for _ in {1..20}; do
      kill -0 "$pid" 2>/dev/null || break
      sleep 0.1
    done
    kill -9 "$pid" 2>/dev/null || true
  fi
  rm -f "$pid_file"
}

stop_stale_children() {
  stop_stale_child "$UPDATE_DIR/run/ngrok.pid"
  stop_stale_child "$UPDATE_DIR/run/cloudflared.pid"
  stop_stale_child "$UPDATE_DIR/run/update-server.pid"

  pkill -f \
    "[s]erve_updates.py $UPDATE_DIR --host 0.0.0.0 --port $PORT" \
    2>/dev/null || true
  pkill -f \
    "[c]loudflared tunnel --url http://127.0.0.1:$PORT" \
    2>/dev/null || true
  pkill -f \
    "[n]grok http.*$PORT" \
    2>/dev/null || true
}

load_helper() {
  unload_helper
  stop_stale_children
  sleep 1

  local attempt
  for attempt in {1..5}; do
    if launchctl bootstrap "gui/$UID" "$PLIST_FILE"; then
      break
    fi

    if [[ "$attempt" == "5" ]]; then
      fail "macOS could not load the update helper."
    fi

    sleep 1
  done

  launchctl kickstart -k "gui/$UID/$LABEL" >/dev/null 2>&1 || true
}

wait_for_worldwide_url() {
  rm -f "$INFO_FILE"

  for _ in {1..120}; do
    if [[ -f "$INFO_FILE" ]] &&
      grep -q '^WORLDWIDE_READY=yes$' "$INFO_FILE"; then
      return 0
    fi
    sleep 0.5
  done

  return 1
}

start_server() {
  command -v python3 >/dev/null 2>&1 || fail "python3 is required."
  prepare_filesystem
  install_ngrok
  check_ngrok_config
  write_launch_agent
  write_awake_agent
  load_awake_helper

  log "Starting the always-on update helper"
  load_helper

  if ! wait_for_worldwide_url; then
    tail -n 60 "$HELPER_LOG" >&2 || true
    tail -n 60 "$UPDATE_DIR/logs/ngrok.log" >&2 || true
    fail "The helper started, but a worldwide URL was not created."
  fi

  log "Update server is online"
  cat "$INFO_FILE"
}

stop_server() {
  unload_helper
  unload_awake_helper
  stop_stale_children
  log "Update helper stopped"
}

restart_server() {
  prepare_filesystem
  install_ngrok
  check_ngrok_config
  write_launch_agent
  write_awake_agent
  load_awake_helper
  log "Restarting the always-on update helper"
  load_helper

  if ! wait_for_worldwide_url; then
    fail "The helper restarted, but a worldwide URL was not created."
  fi

  cat "$INFO_FILE"
}

show_status() {
  launchctl print "gui/$UID/$LABEL" 2>/dev/null |
    sed -n '1,35p' || printf 'Update helper is not loaded.\n'

  if [[ -f "$INFO_FILE" ]]; then
    printf '\n'
    cat "$INFO_FILE"
  fi

  printf '\nAwake helper:\n'
  launchctl print "gui/$UID/$AWAKE_LABEL" 2>/dev/null |
    sed -n '1,18p' || printf 'Awake helper is not loaded.\n'
}

uninstall_helper() {
  unload_helper
  unload_awake_helper
  rm -f "$PLIST_FILE"
  rm -f "$AWAKE_PLIST_FILE"
  log "Update helper removed from Login Items"
}

start_awake_helper() {
  prepare_filesystem
  write_awake_agent
  load_awake_helper
  log "Mac sleep prevention helper is running"
}

case "$COMMAND" in
start)
  start_server
  ;;
restart)
  restart_server
  ;;
stop)
  stop_server
  ;;
status)
  show_status
  ;;
awake)
  start_awake_helper
  ;;
uninstall)
  uninstall_helper
  ;;
*)
  fail "Usage: $0 [start|restart|stop|status|awake|uninstall]"
  ;;
esac
