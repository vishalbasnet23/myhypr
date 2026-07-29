#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# for changing Hyprland Layouts (Master or Dwindle) on the fly
#
# MIGRATION (Lua config): every `hyprctl keyword ...` here is dead
# ("keyword can't work with non-legacy parsers. Use eval."). Replaced with `hyprctl eval`
# calling hl.config() / hl.unbind() / hl.bind(). Dispatcher renames applied:
#     cyclenext            -> hl.dsp.window.cycle_next()
#     cyclenext,prev       -> hl.dsp.window.cycle_next({ next = false })
#     layoutmsg,cyclenext  -> hl.dsp.layout("cyclenext")
#     togglesplit          -> hl.dsp.layout("togglesplit")
#
# BUGFIX while migrating: hl.unbind("SUPER + J") is case-insensitive, so it also removes
# the lowercase SUPER+j / SUPER+k movefocus binds from UserConfigs/UserKeybinds.lua.
# The old script had this same flaw and silently ate those binds until the next reload.
# We now re-add them after unbinding.

notif="$HOME/.config/swaync/images/ja.png"

LAYOUT=$(hyprctl -j getoption general:layout | jq '.str' | sed 's/"//g')

ev() {
  local result
  result=$(hyprctl eval "$1" 2>&1)
  if [[ "$result" != "ok" ]]; then
    notify-send -e -u critical -i "$notif" " Layout" " Failed: $1 -> $result"
    exit 1
  fi
}

# Re-add the vim-style focus binds that the case-insensitive unbind removes.
restore_focus_binds() {
  ev 'hl.bind("SUPER + j", hl.dsp.focus({ direction = "d" }))'
  ev 'hl.bind("SUPER + k", hl.dsp.focus({ direction = "u" }))'
}

case $LAYOUT in
"master")
  ev 'hl.config({ general = { layout = "dwindle" } })'
  ev 'hl.unbind("SUPER + J")'
  ev 'hl.unbind("SUPER + K")'
  ev 'hl.bind("SUPER + J", hl.dsp.window.cycle_next())'
  ev 'hl.bind("SUPER + K", hl.dsp.window.cycle_next({ next = false }))'
  ev 'hl.bind("SUPER + O", hl.dsp.layout("togglesplit"))'
  restore_focus_binds
  notify-send -e -u low -i "$notif" " Dwindle Layout"
  ;;
"dwindle")
  ev 'hl.config({ general = { layout = "master" } })'
  ev 'hl.unbind("SUPER + J")'
  ev 'hl.unbind("SUPER + K")'
  ev 'hl.unbind("SUPER + O")'
  ev 'hl.bind("SUPER + J", hl.dsp.layout("cyclenext"))'
  ev 'hl.bind("SUPER + K", hl.dsp.layout("cycleprev"))'
  restore_focus_binds
  notify-send -e -u low -i "$notif" " Master Layout"
  ;;
*) ;;

esac
