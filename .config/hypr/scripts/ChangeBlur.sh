#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for changing blurs on the fly
#
# MIGRATION (Lua config): `hyprctl keyword decoration:blur:size 2` no longer works
# ("keyword can't work with non-legacy parsers. Use eval."). Replaced with a single
# `hyprctl eval` that applies both values through hl.config(). Reads still work via
# `hyprctl getoption`, so the state check is unchanged.

notif="$HOME/.config/swaync/images"

STATE=$(hyprctl -j getoption decoration:blur:passes | jq ".int")

set_blur() {
  local size="$1" passes="$2"
  local result
  result=$(hyprctl eval "hl.config({ decoration = { blur = { size = $size, passes = $passes } } })" 2>&1)
  if [[ "$result" != "ok" ]]; then
    notify-send -e -u critical -i "$notif/error.png" " Blur" " Failed: $result"
    exit 1
  fi
}

if [ "${STATE}" == "2" ]; then
  set_blur 2 1
  notify-send -e -u low -i "$notif/note.png" " Less Blur"
else
  set_blur 5 2
  notify-send -e -u low -i "$notif/ja.png" " Normal Blur"
fi
