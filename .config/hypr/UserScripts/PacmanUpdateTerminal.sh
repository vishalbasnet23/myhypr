#!/usr/bin/env bash

# Terminal to use (change if using kitty/alacritty)
TERM="kitty"

if command -v cachyos &>/dev/null; then
  CMD="sudo cachyos -Syu"
else
  CMD="sudo pacman -Syu"
fi

# Open terminal in a FLOATING Hyprland window
hyprctl dispatch exec "[float;size 1200 800] $TERM -e bash -c \"$CMD; echo; echo 'Done. Press ENTER to close.'; read\""
