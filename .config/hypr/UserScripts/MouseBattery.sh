#!/bin/bash
# Waybar custom module: Bluetooth mouse battery.
# Prints one line of JSON, or nothing at all when the mouse is off/unpaired,
# so waybar collapses the module instead of showing an error.

MAC="E3:48:D4:82:17:2C"
DEV="dev_${MAC//:/_}"

level=""; src=""

# 1. org.bluez.Battery1 straight over D-Bus - cheapest read.
read_bluez() {
	local out
	out=$(busctl get-property org.bluez "/org/bluez/hci0/${DEV}" \
		org.bluez.Battery1 Percentage 2>/dev/null) || return 1
	[[ $out =~ ^y[[:space:]]+([0-9]+)$ ]] || return 1
	level="${BASH_REMATCH[1]}"; src="org.bluez.Battery1 (busctl)"
}

# 2. Same source, different reader.
read_bctl() {
	local out
	out=$(bluetoothctl info "$MAC" 2>/dev/null | grep -m1 -i 'Battery Percentage') || return 1
	[[ $out =~ \(([0-9]+)\) ]] || return 1
	level="${BASH_REMATCH[1]}"; src="bluetoothctl"
}

# 3. UPower - last resort.
read_upower() {
	local path out
	path=$(upower -e 2>/dev/null | grep -m1 "$DEV") || return 1
	out=$(upower -i "$path" 2>/dev/null | grep -m1 'percentage') || return 1
	[[ $out =~ ([0-9]+)% ]] || return 1
	level="${BASH_REMATCH[1]}"; src="UPower"
}

# Mouse off or unpaired: stay silent, module collapses.
bluetoothctl info "$MAC" 2>/dev/null | grep -q 'Connected: yes' || exit 0

read_bluez || read_bctl || read_upower || exit 0

name=$(bluetoothctl info "$MAC" 2>/dev/null | sed -n 's/^[[:space:]]*Name: //p' | head -1)
[ -z "$name" ] && name="Bluetooth mouse"

if   [ "$level" -le 15 ]; then class="critical"
elif [ "$level" -le 30 ]; then class="warning"
else                           class="good"
fi

jq -nc --arg t "󰍽 ${level}%" \
	--arg tip "${name} (${MAC})"$'\n'"Battery ${level}% via ${src}" \
	--arg c "$class" --argjson p "$level" \
	'{text:$t, tooltip:$tip, class:$c, percentage:$p}'
