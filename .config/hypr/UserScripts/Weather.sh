#!/usr/bin/env bash

CACHE_DIR="$HOME/.cache/rbn"
CACHE_FILE="$CACHE_DIR/Weather.cache"
mkdir -p "$CACHE_DIR"

# Get location (approx)
LOC=$(curl -s https://ipinfo.io/loc)
LAT=$(echo "$LOC" | cut -d',' -f1)
LON=$(echo "$LOC" | cut -d',' -f2)

if [[ -z $LAT || -z $LON ]]; then
  echo '{"text":"N/A ","alt":"NoLocation","tooltip":"Location error"}'
  exit 1
fi

# Fetch weather
WEATHER=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=$LAT&longitude=$LON&current=temperature_2m,weather_code")

# Save to cache
echo "$WEATHER" >"$CACHE_FILE"

TEMP=$(jq '.current.temperature_2m' <<<"$WEATHER")
CODE=$(jq '.current.weather_code' <<<"$WEATHER")

# Simple icon map
case $CODE in
0) ICON="☀️" ;;
1 | 2 | 3) ICON="⛅" ;;
45 | 48) ICON="🌫️" ;;
51 | 53 | 55) ICON="🌦️" ;;
61 | 63 | 65) ICON="🌧️" ;;
71 | 73 | 75) ICON="❄️" ;;
95 | 96 | 99) ICON="⛈️" ;;
*) ICON="❓" ;;
esac

echo "{\"text\":\"$TEMP°C $ICON\",\"alt\":\"Weather\",\"tooltip\":\"Temp: $TEMP°C\"}"

