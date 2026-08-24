#!/bin/bash
# Waybar custom module: window count per workspace, as dots.
#   1●  2●●●  3●
# Long-running: prints one JSON line at startup and one on every Hyprland event
# that could change the counts, so it never polls. Waybar keeps reading stdout.

SOCKET="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
[ -S "$SOCKET" ] || exit 0

emit() {
	local active
	active=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // 0')
	hyprctl clients -j 2>/dev/null | jq -rc --argjson active "${active:-0}" '
		# Negative ids are the special/scratchpad workspaces - leave them out.
		[ .[] | select(.workspace.id > 0) ]
		| group_by(.workspace.id)
		| map({ id: .[0].workspace.id, n: length, apps: (map(.class) | unique) })
		| sort_by(.id)
		| {
			text: (
				map(
					(if .id == $active then "<b>\(.id)</b>" else "\(.id)" end)
					+ ("●" * .n)
				) | join("  ")
			),
			tooltip: (
				if length == 0 then "No windows open"
				else (map("Workspace \(.id): \(.n) - \(.apps | join(", "))") | join("\n"))
				end
			),
			class: (if length == 0 then "empty" else "populated" end),
		}'
}

emit

# Only these events can change a count or move the highlight.
# socat runs as a named coproc so its pid is known and can be killed on exit.
# Piping it into the loop instead leaves socat orphaned when waybar kills only
# the top-level script pid.
#
# The trap covers a clean exit, but not SIGKILL - and an idle socat never
# notices its reader is gone, because it only learns that by writing. So socat
# also gets the kernel's parent-death signal. `exec` matters: without it socat's
# parent is the coproc subshell rather than this script, and the death signal
# would fire on the wrong process exiting.
trap 'kill "$EV_PID" 2>/dev/null' EXIT INT TERM HUP
coproc EV { exec setpriv --pdeathsig TERM socat -u "UNIX-CONNECT:${SOCKET}" - 2>/dev/null; }

while read -r line <&"${EV[0]}"; do
	case "$line" in
		workspace\>\>* | openwindow\>\>* | closewindow\>\>* | movewindow\>\>* | \
		focusedmon\>\>* | movewindowv2\>\>* | createworkspace\>\>* | destroyworkspace\>\>*)
			emit
			;;
	esac
done
