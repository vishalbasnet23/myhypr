#!/bin/bash
# Swaps the bar/dashboard position profile (top-bar+left-dashboard vs
# left-bar+top-dashboard) by copying the chosen profile's files over the
# live modules/ tree, then restarts the shell.
#
# These are the ~17 files whose layout is position-specific (axis, anchors,
# hover-zone math). Everything else (colours, rounding, workspace display
# type, etc.) is a plain shell.json config value and is NOT touched here -
# switching position never resets those.
#
# Usage: switch.sh top|left

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CAELESTIA="$(dirname "$DIR")"

case "$1" in
  top|left) ;;
  *)
    notify-send -u critical "Bar position" "Usage: switch.sh top|left"
    exit 1
    ;;
esac

PROFILE="$DIR/bar-$1"
if [[ ! -d "$PROFILE" ]]; then
  notify-send -u critical "Bar position" "Profile '$1' not found at $PROFILE"
  exit 1
fi

while IFS= read -r -d '' f; do
  rel="${f#"$PROFILE"/}"
  cp "$f" "$CAELESTIA/$rel"
done < <(find "$PROFILE" -type f -print0)

printf '%s' "$1" > "$DIR/current"

pkill -f "qs -c caelestia" || true
sleep 1
nohup qs -c caelestia >/dev/null 2>&1 &
disown

notify-send -u low -i preferences-desktop "Bar position" "Switched to $1, shell restarted"
