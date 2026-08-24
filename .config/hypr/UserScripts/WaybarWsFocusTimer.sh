#!/bin/bash
# Waybar custom module: how long the current workspace has been focused.
#   󱎫 12m
# A polling module cannot do this - it has no way to know when you arrived - so
# this holds the arrival time itself.
#
# One process, no state file and no background ticker: `read -t 1` on the event
# coproc either returns a Hyprland event (restamp) or times out after a second
# (re-render). An earlier version split ticker and listener across two processes
# sharing a mktemp file, which leaked both the file and the ticker whenever the
# script was SIGKILLed - waybar does exactly that on restart.
#
# Only prints when the rendered string changes, so it is one printf a minute
# once past the first minute rather than one a second.

SOCKET="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
WARN_MINUTES=25   # .warning after this long in one workspace
LONG_MINUTES=60   # .critical after this long
ICON="󱎫"

[ -S "$SOCKET" ] || exit 0

trap 'kill "$EV_PID" 2>/dev/null' EXIT INT TERM HUP

current_ws() {
	hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // 0'
}

human() {
	local s="$1"
	if   [ "$s" -lt 60 ];   then printf '%ds' "$s"
	elif [ "$s" -lt 3600 ]; then printf '%dm' "$((s / 60))"
	else                         printf '%dh%02dm' "$((s / 3600))" "$(((s % 3600) / 60))"
	fi
}

ws=$(current_ws)
since=$EPOCHSECONDS
last=""

render() {
	local elapsed label class line pretty
	elapsed=$((EPOCHSECONDS - since))
	[ "$elapsed" -lt 0 ] && elapsed=0
	pretty=$(human "$elapsed")
	label="${ICON} ${pretty}"

	if   [ "$elapsed" -ge $((LONG_MINUTES * 60)) ]; then class="critical"
	elif [ "$elapsed" -ge $((WARN_MINUTES * 60)) ]; then class="warning"
	else                                                 class="good"
	fi

	line="${label}|${class}"
	[ "$line" = "$last" ] && return 0
	last="$line"
	# No jq: none of these values can contain JSON metacharacters.
	printf '{"text":"%s","tooltip":"Workspace %s focused for %s","class":"%s"}\n' \
		"$label" "${ws:-0}" "$pretty" "$class"
}

render

# `exec` so socat's parent is this script and not the coproc subshell, which is
# what the parent-death signal keys off. The trap handles a clean exit; this
# handles SIGKILL, which no trap can catch, and which an idle socat would
# otherwise never notice - it only learns its reader is gone by writing.
coproc EV { exec setpriv --pdeathsig TERM socat -u "UNIX-CONNECT:${SOCKET}" - 2>/dev/null; }

while :; do
	if read -t 1 -r line <&"${EV[0]}"; then
		case "$line" in
			workspace\>\>* | focusedmon\>\>*)
				ws=$(current_ws)
				since=$EPOCHSECONDS
				;;
		esac
	else
		# read returns >128 on timeout and 1 on EOF; EOF means socat is gone.
		[ "$?" -gt 128 ] || break
	fi
	render
done
