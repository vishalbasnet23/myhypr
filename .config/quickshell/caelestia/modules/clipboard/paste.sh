#!/bin/bash

# Clipboard action helper for the caelestia clipboard module. Reads entries by
# index from the history JSON so large payloads never travel through argv.
# Stands in for omarchy's bin/omarchy-clipboard-paste-{text,file} / -open.
#
# Usage:
#   paste.sh paste-text  <index>            copy entry to clipboard, then fake Ctrl+V
#   paste.sh copy-text   <index>            copy entry to clipboard only
#   paste.sh paste-image <mime> <path>      copy image file, then fake Ctrl+V
#   paste.sh copy-image  <mime> <path>      copy image file only
#   paste.sh open        <index>            xdg-open the entry (image, file:// URI, path or URL)

set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/clipboard"
HISTORY_FILE="$STATE_DIR/history.json"
# The overlay window must be gone and focus back on the target app before the
# synthetic keypress lands.
PASTE_DELAY="${CLIPBOARD_PASTE_DELAY:-0.25}"

# Hyprland's Lua config has no fakeinput dispatcher; send_shortcut is its
# replacement. Shift+Insert because it pastes at emulator/toolkit level:
# terminals (kitty) paste the primary selection with it, GUI toolkits paste
# the clipboard - hence both selections get the payload below. No window
# argument: after the picker closes, focus is back on the target app.
fake_paste() {
  sleep "$PASTE_DELAY"
  hyprctl dispatch 'hl.dsp.send_shortcut({ mods = "SHIFT", key = "INSERT" })' >/dev/null 2>&1 ||
    notify-send -a caelestia "Clipboard" "Paste failed: copied to clipboard instead"
}

entry_field() {
  jq -r --argjson i "$1" --arg f "$2" '.[$i][$f] // empty' "$HISTORY_FILE" 2>/dev/null || true
}

mode="${1:-}"
[[ $# -gt 0 ]] && shift

case "$mode" in
paste-text | copy-text)
  index="${1:?index required}"
  text="$(entry_field "$index" text)"
  [[ -n "$text" ]] || exit 0
  printf '%s' "$text" | wl-copy --type text/plain
  printf '%s' "$text" | wl-copy --type text/plain -p
  [[ "$mode" == paste-text ]] && fake_paste
  ;;

paste-image | copy-image)
  mime="${1:?mime required}"
  path="${2:?path required}"
  [[ -f "$path" ]] || exit 0
  wl-copy --type "$mime" <"$path"
  wl-copy --type "$mime" -p <"$path"
  [[ "$mode" == paste-image ]] && fake_paste
  ;;

open)
  index="${1:?index required}"
  type="$(entry_field "$index" type)"

  if [[ "$type" == image ]]; then
    path="$(entry_field "$index" path)"
    [[ -f "$path" ]] || exit 0
    xdg-open "$path" >/dev/null 2>&1 &
    exit 0
  fi

  text="$(entry_field "$index" text)"
  [[ -n "$text" ]] || exit 0
  first="$(head -n1 <<<"$text")"

  if [[ "$first" == file://* ]]; then
    xdg-open "$first" >/dev/null 2>&1 &
  elif [[ -e "$first" ]]; then
    xdg-open "$first" >/dev/null 2>&1 &
  elif [[ "$first" =~ ^[a-zA-Z][a-zA-Z0-9+.-]*:// ]]; then
    xdg-open "$first" >/dev/null 2>&1 &
  else
    printf '%s' "$text" | wl-copy --type text/plain
    notify-send -a caelestia "Clipboard" "Nothing to open - entry copied instead"
  fi
  ;;

*)
  echo "usage: paste.sh {paste-text|copy-text|paste-image|copy-image|open} ..." >&2
  exit 2
  ;;
esac
