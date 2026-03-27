#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
# Random Wallpaper with wpaperd + random transitions (CTRL ALT W)

SCRIPTSDIR="$HOME/.config/hypr/scripts"
CONFIG="$HOME/.config/wpaperd/config.toml"

# Get the currently focused monitor name
MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

# List of wpaperd transitions
TRANSITIONS=(
  "book-flip"
  "bounce"
  "bow-tie-horizontal"
  "bow-tie-vertical"
  "circle"
  "circle-open"
  "cross-warp"
  "directional"
  "dissolve"
  "doom"
  "dreamy"
  "fade"
  "glitch-displace"
  "grid-flip"
  "hexagonalize"
  "pixelize"
  "ripple"
  "rotate-scale-fade"
  "simple-zoom"
  "swirl"
  "water-drop"
  "window-blinds"
)

# Pick a random transition
RANDOM_TRANSITION=${TRANSITIONS[$RANDOM % ${#TRANSITIONS[@]}]}

# Update the transition in config
sed -i '/^\[default\.transition\./d' "$CONFIG"
echo "" >>"$CONFIG"
echo "[default.transition.$RANDOM_TRANSITION]" >>"$CONFIG"

# Cycle wallpaper on the focused monitor only (monitor name is required)
wpaperctl next "$MONITOR"

# Get current wallpaper path using wpaperd's symlink
CURRENT_WALL=$(readlink -f "$HOME/.local/state/wpaperd/wallpapers/$MONITOR")

# Run wallust/color theming hook
if [ -f "$SCRIPTSDIR/WallustSwww.sh" ]; then
  "$SCRIPTSDIR/WallustSwww.sh" "$CURRENT_WALL"
fi
