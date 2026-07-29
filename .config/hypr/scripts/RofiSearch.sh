#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# For Searching via web browsers

# MIGRATION (Lua config): 01-UserDefaults is now a .lua file returning a table, so the old
# `sed 's/\$//g' | eval` trick against the .conf no longer works. The shared helper reads
# the Lua table and exports $term / $files / $edit / $Search_Engine.
source "$HOME/.config/hypr/scripts/UserDefaults.sh" || exit 1

# Check if $Search_Engine is set correctly
if [[ -z "$Search_Engine" ]]; then
    echo "Error: \$Search_Engine is not set in the configuration file!"
    exit 1
fi

# Rofi theme and message
rofi_theme="$HOME/.config/rofi/config-search.rasi"
msg='‼️ **note** ‼️ search via default web browser'

# Kill Rofi if already running before execution
if pgrep -x "rofi" >/dev/null; then
    pkill rofi
fi

# Open Rofi and pass the selected query to xdg-open for Google search
echo "" | rofi -dmenu -config "$rofi_theme" -mesg "$msg" | xargs -I{} xdg-open $Search_Engine