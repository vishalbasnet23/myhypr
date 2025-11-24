#!/usr/bin/env bash

# Check for package updates (Pacman / CachyOS)
UPDATE_COUNT=0

if command -v cachyos &>/dev/null; then
  # CachyOS: list updates without updating
  UPDATE_COUNT=$(cachyos update --print 2>/dev/null | wc -l)
else
  # Arch: checkupdates gives available upgrades
  UPDATE_COUNT=$(checkupdates 2>/dev/null | wc -l)
fi

if [ "$UPDATE_COUNT" -gt 0 ]; then
  echo "󰁈 $UPDATE_COUNT"
else
  echo ""
fi
