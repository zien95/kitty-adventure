#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf '%s\n' 'Pet Fiasco — Xenix Updates' \
    'Usage: bash xenix-updates.sh [list|apk|ipa|macos|web] [output-directory]' \
    'With no arguments, lists the current release download links.'
}

mode="${1:-list}"
case "$mode" in
  -h|--help|help) usage; exit 0 ;;
  list|apk|ipa|macos|web) ;;
  *) usage >&2; exit 2 ;;
esac
command -v curl >/dev/null || { printf '%s\n' 'curl is required.' >&2; exit 1; }
command -v python3 >/dev/null || { printf '%s\n' 'Python 3 is required.' >&2; exit 1; }

manifest_url="${PET_FIASCO_MANIFEST_URL:-https://pet-fiasco.web.app/latest.json}"
manifest=$(curl -fsSL --proto '=https' --proto-redir '=https' --max-time 30 "$manifest_url")
selection=$(printf '%s' "$manifest" | python3 -c '
import json, sys
from urllib.parse import urlsplit
data = json.load(sys.stdin)
keys = {"apk":"apk_url", "ipa":"ipa_url", "macos":"macos_url", "web":"web_zip_url"}
if sys.argv[1] == "list":
    print("Pet Fiasco " + str(data["version"]))
    for name, key in keys.items():
        print(name + ": " + data[key])
else:
    url = data[keys[sys.argv[1]]]
    parsed = urlsplit(url)
    if parsed.scheme != "https" or parsed.netloc != "github.com" or not parsed.path.startswith("/zien95/kitty-adventure/releases/download/"):
        raise SystemExit("The manifest does not contain a trusted release URL.")
    print(url)
' "$mode")
if [[ "$mode" == list ]]; then printf '%s\n' "$selection"; exit 0; fi

directory="${2:-.}"
[[ -d "$directory" ]] || { printf '%s\n' 'Output directory must already exist.' >&2; exit 1; }
filename="${selection##*/}"
[[ "$filename" =~ ^[A-Za-z0-9._-]+$ ]] || { printf '%s\n' 'Invalid download filename.' >&2; exit 1; }
output="$directory/$filename"
[[ ! -e "$output" ]] || { printf 'File already exists: %s\n' "$output" >&2; exit 1; }
partial=$(mktemp "$directory/.pet-fiasco-download.XXXXXX")
trap '[[ ! -f "$partial" ]] || rm "$partial"' EXIT
curl -fL --proto '=https' --proto-redir '=https' --output "$partial" "$selection"
mv "$partial" "$output"
printf 'Downloaded: %s\n' "$output"
