#!/bin/bash

wallDIR="$HOME/Pictures/wallpapers"
focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

PICS=($(find -L "${wallDIR}" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \
  -o -name "*.pnm" -o -name "*.tga" -o -name "*.tiff" -o -name "*.webp" \
  -o -name "*.bmp" -o -name "*.farbfeld" -o -name "*.gif" \)))
RANDOMPICS=${PICS[$RANDOM % ${#PICS[@]}]}

# Start daemon if not running
awww query || awww-daemon

awww img -o "$focused_monitor" "$RANDOMPICS" --transition-fps 120 --transition-type random --transition-step 90

eDP1_WALL=$(awww query | awk -F'image: ' '/eDP-1/{print $2}')
ln -sf "$eDP1_WALL" "$HOME/.cache/current_wallpaper"
