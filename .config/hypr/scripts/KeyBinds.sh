#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# searchable enabled keybinds using rofi
#
# MIGRATION (Lua config): the bind files are now .lua, so the grep target changed from
# `^bind` to `^hl.bind(`.
#
# NOTE on why this still parses files rather than asking Hyprland: `hyprctl binds -j`
# looks like the obvious source, but under a Lua config every bind reports its dispatcher
# as the opaque `__lua` with an integer arg, and `description` is empty unless you set one
# on each bind. That would turn this menu into a list of "__lua 7". Reading the config
# keeps the human-readable trailing comments, which is what makes this menu useful.

# kill yad to not interfere with this binds
pkill yad || true

# check if rofi is already running
if pidof rofi >/dev/null; then
  pkill rofi
fi

# define the config files
keybinds_lua="$HOME/.config/hypr/configs/Keybinds.lua"
user_keybinds_lua="$HOME/.config/hypr/UserConfigs/UserKeybinds.lua"
laptop_lua="$HOME/.config/hypr/UserConfigs/Laptops.lua"
rofi_theme="$HOME/.config/rofi/config-keybinds.rasi"
msg='☣️ NOTE ☣️: Clicking with Mouse or Pressing ENTER will have NO function'

# collect the files that actually exist
files=()
for f in "$keybinds_lua" "$user_keybinds_lua" "$laptop_lua"; do
  [[ -f "$f" ]] && files+=("$f")
done

if [[ ${#files[@]} -eq 0 ]]; then
  echo "no keybind files found."
  exit 1
fi

# Pull the hl.bind() lines and tidy them for display:
#   - drop the leading `hl.bind(`
#   - `mainMod .. "` -> `"SUPER`, so `mainMod .. " + Q"` reads as `"SUPER + Q"`
#   - drop the `hl.dsp.` namespace noise
#   - collapse the alignment padding before trailing `--` comments
keybinds=$(grep -hE '^[[:space:]]*hl\.bind\(' "${files[@]}" |
  sed -e 's/^[[:space:]]*hl\.bind(//' \
    -e 's/mainMod \.\. "/"SUPER/g' \
    -e 's/hl\.dsp\.//g' \
    -e 's/[[:space:]]\{2,\}/  /g')

# The 0-9 workspace binds are generated in a loop, so they have no literal line to show.
keybinds+=$'\n''"SUPER + code:10..19"  -> focus workspace 1-10          -- number row 1,2,...,0'
keybinds+=$'\n''"SUPER + SHIFT + code:10..19"  -> move window to workspace 1-10 and follow'
keybinds+=$'\n''"SUPER + CTRL + code:10..19"  -> move window to workspace 1-10 silently'

# check for any keybinds to display
if [[ -z "$keybinds" ]]; then
  echo "no keybinds found."
  exit 1
fi

# use rofi to display the keybinds
echo "$keybinds" | rofi -dmenu -i -config "$rofi_theme" -mesg "$msg"
