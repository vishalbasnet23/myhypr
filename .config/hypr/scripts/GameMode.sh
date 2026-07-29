#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Game Mode. Turning off all animations
#
# MIGRATION (Lua config):
#  * the `hyprctl --batch "keyword ...; keyword ..."` block is dead
#    ("keyword can't work with non-legacy parsers. Use eval.") -> one `hyprctl eval`
#    applying the whole set through hl.config().
#  * `hyprctl keyword "windowrule opacity ..., ^(.*)$"` -> hl.window_rule(). It is given a
#    NAME so it can be dropped again on exit; named rules also outrank anonymous ones,
#    which is what you want for a global override.
#
# BUGFIX while migrating (both pre-existing):
#  * the state probe compared against `1`, but `hyprctl getoption animations:enabled` now
#    reports `bool: true`, so the enable branch could never be taken. Now read as JSON.
#  * the trailing `hyprctl reload` was unreachable (both branches `exit`), so disabling
#    game mode never actually restored animations/blur/gaps — it only restarted the
#    wallpaper daemon. `hyprctl reload` re-reads the Lua config and re-applies it
#    (verified), so it now runs in the disable branch.

notif="$HOME/.config/swaync/images/ja.png"
SCRIPTSDIR="$HOME/.config/hypr/scripts"

# true / false, regardless of whether Hyprland reports it as bool or int
HYPRGAMEMODE=$(hyprctl -j getoption animations:enabled |
  jq -r 'if has("bool") then (.bool | tostring) elif has("int") then (.int > 0 | tostring) else "true" end')

ev() {
  local result
  result=$(hyprctl eval "$1" 2>&1)
  if [[ "$result" != "ok" ]]; then
    notify-send -e -u critical -i "$notif" " Gamemode" " Failed: $result"
    exit 1
  fi
}

if [ "$HYPRGAMEMODE" = "true" ]; then
  ev 'hl.config({
        animations = { enabled = false },
        decoration = { shadow = { enabled = false }, blur = { enabled = false }, rounding = 0 },
        general    = { gaps_in = 0, gaps_out = 0, border_size = 1 },
      })'
  ev 'hl.window_rule({
        name    = "gamemode-force-opaque",
        match   = { class = ".*" },
        opacity = "1 override 1 override 1 override",
      })'
  swww kill
  notify-send -e -u low -i "$notif" " Gamemode:" " enabled"
  exit
else
  # Drop the game-mode override, then reload to restore everything from the Lua config.
  hyprctl eval 'local r = hl.window_rule({ name = "gamemode-force-opaque", match = { class = ".*" } }); r:set_enabled(false)' >/dev/null 2>&1
  hyprctl reload >/dev/null
  swww-daemon --format xrgb && swww img "$HOME/.config/rofi/.current_wallpaper" &
  sleep 0.1
  ${SCRIPTSDIR}/WallustSwww.sh
  sleep 0.5
  ${SCRIPTSDIR}/Refresh.sh
  notify-send -e -u normal -i "$notif" " Gamemode:" " disabled"
  exit
fi
