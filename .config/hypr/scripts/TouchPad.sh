#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# For disabling touchpad.
# use hyprctl devices to get your system touchpad device name
# source https://github.com/hyprwm/Hyprland/discussions/4283?sort=new#discussioncomment-8648109
#
# MIGRATION (Lua config): this used to run
#     hyprctl keyword '$TOUCHPAD_ENABLED' "true" -r
# which set a hyprlang *variable* that UserConfigs/Laptops.conf read back. Neither thing
# exists any more: the Lua config has no global $variables, and `hyprctl keyword` refuses
# to run at all ("keyword can't work with non-legacy parsers. Use eval."). We now call
# hl.device() directly, which is what Laptops.lua does at startup.

notif="$HOME/.config/swaync/images/ja.png"

export STATUS_FILE="$XDG_RUNTIME_DIR/touchpad.status"

# Device name. Auto-detected so this keeps working if the hardware changes; the value
# configured in UserConfigs/Laptops.lua is the fallback.
TOUCHPAD_FALLBACK="asue1209:00-04f3:319f-touchpad"
TOUCHPAD_DEVICE=$(hyprctl devices -j 2>/dev/null |
  jq -r '[.mice[]?.name] | map(select(test("touchpad"; "i"))) | first // empty')
[[ -z "$TOUCHPAD_DEVICE" ]] && TOUCHPAD_DEVICE="$TOUCHPAD_FALLBACK"

apply_touchpad() {
  local state="$1" # true | false
  local result
  result=$(hyprctl eval "hl.device({ name = \"$TOUCHPAD_DEVICE\", enabled = $state })" 2>&1)
  if [[ "$result" != "ok" ]]; then
    notify-send -u critical -i "$notif" " Touchpad" " Failed: $result"
    return 1
  fi
}

enable_touchpad() {
  apply_touchpad true || return 1
  printf "true" >"$STATUS_FILE"
  notify-send -u low -i "$notif" " Enabling" " touchpad"
}

disable_touchpad() {
  apply_touchpad false || return 1
  printf "false" >"$STATUS_FILE"
  notify-send -u low -i "$notif" " Disabling" " touchpad"
}

if ! [ -f "$STATUS_FILE" ]; then
  enable_touchpad
else
  if [ "$(cat "$STATUS_FILE")" = "true" ]; then
    disable_touchpad
  elif [ "$(cat "$STATUS_FILE")" = "false" ]; then
    enable_touchpad
  fi
fi
