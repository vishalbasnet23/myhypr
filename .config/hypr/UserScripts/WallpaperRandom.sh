#!/bin/bash

wallDIR="$HOME/Pictures/wallpapers"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

PICS=($(find -L "${wallDIR}" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \
  -o -name "*.pnm" -o -name "*.tga" -o -name "*.tiff" -o -name "*.webp" \
  -o -name "*.bmp" -o -name "*.farbfeld" -o -name "*.gif" \)))
RANDOMPICS=${PICS[$RANDOM % ${#PICS[@]}]}

# Transition config
FPS=30

# Random transition — awww supports: simple, left, right, top, bottom,
# wipe, grow, center, outer, any, random (random picks one itself)
TRANSITIONS=(simple left right top bottom wipe grow center outer any)
TYPE=${TRANSITIONS[$RANDOM % ${#TRANSITIONS[@]}]}

AWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-step 90"

# Start daemon if not running
awww query || awww-daemon

awww img -o "$focused_monitor" "$RANDOMPICS"
