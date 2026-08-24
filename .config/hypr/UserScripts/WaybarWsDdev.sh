#!/bin/bash
# Waybar custom module: the ddev project running in each workspace.
#   2 󰡨 forge   5 󰡨 nica
# Reads the ddev project registry (~/.config/ddev/project_list.yaml) rather than
# shelling out to `ddev list`, which takes ~1.7s and wraps its JSON in log
# records - far too slow for an event-driven module.
# A workspace is matched by walking each window's process tree and reading
# /proc/<pid>/cwd: the window pid is the terminal or editor, and the shell that
# actually sits inside the project is a descendant of it.
# Long-running: emits on Hyprland events instead of polling.

SOCKET="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
REGISTRY="${XDG_CONFIG_HOME:-$HOME/.config}/ddev/project_list.yaml"
MAX_DEPTH=5
ICON="󰡨"

[ -S "$SOCKET" ] || exit 0
[ -r "$REGISTRY" ] || exit 0

# approot -> project name. The registry is flat YAML: "name:" then "  approot: /path".
declare -A PROJECTS
load_registry() {
	local name=""
	while IFS= read -r line; do
		case "$line" in
			[![:space:]]*:) name="${line%:}" ;;
			*approot:*)
				local path="${line#*approot:}"
				path="${path#"${path%%[![:space:]]*}"}"
				[ -n "$name" ] && [ -n "$path" ] && PROJECTS["$path"]="$name"
				;;
		esac
	done < "$REGISTRY"
}
load_registry
[ "${#PROJECTS[@]}" -gt 0 ] || exit 0

# Longest-prefix match so a project nested inside another still resolves.
project_for_cwd() {
	local cwd="$1" best="" best_len=0 root
	for root in "${!PROJECTS[@]}"; do
		case "$cwd" in
			"$root" | "$root"/*)
				if [ "${#root}" -gt "$best_len" ]; then
					best="${PROJECTS[$root]}"; best_len="${#root}"
				fi
				;;
		esac
	done
	printf '%s' "$best"
}

# ppid -> children, built in one /proc pass per emit. One scan beats a pgrep
# per pid, which cost ~2s of CPU on a normal window count.
declare -A CHILDREN
build_child_map() {
	local d pid stat rest ppid
	CHILDREN=()
	for d in /proc/[0-9]*; do
		pid="${d#/proc/}"
		# 2>/dev/null goes BEFORE the redirect - they are set up left to right, so
		# a pid that exits mid-scan would otherwise report "No such file or
		# directory" straight into waybar's stdin.
		read -r stat 2>/dev/null < "$d/stat" || continue
		# Field 2 is the comm and can contain spaces and parens, so cut past the
		# last ")" before splitting. After that, $1 is state and $2 is the ppid.
		rest="${stat##*') '}"
		# shellcheck disable=SC2086
		set -- $rest
		ppid="$2"
		[ -n "$ppid" ] && CHILDREN[$ppid]+="$pid "
	done
}

# The window pid plus its descendants, breadth-first, depth-capped.
project_for_pid() {
	local frontier=("$1") depth=0 next=() pid cwd hit child
	while [ "$depth" -lt "$MAX_DEPTH" ] && [ "${#frontier[@]}" -gt 0 ]; do
		next=()
		for pid in "${frontier[@]}"; do
			cwd=$(readlink "/proc/$pid/cwd" 2>/dev/null)
			if [ -n "$cwd" ]; then
				hit=$(project_for_cwd "$cwd")
				if [ -n "$hit" ]; then printf '%s' "$hit"; return 0; fi
			fi
			# shellcheck disable=SC2086
			for child in ${CHILDREN[$pid]}; do next+=("$child"); done
		done
		frontier=("${next[@]}")
		depth=$((depth + 1))
	done
	return 1
}

# Debug affordance: WaybarWsDdev.sh --probe-pid <pid> prints the project that
# pid resolves to, so the matcher can be checked without opening a window.
if [ "$1" = "--probe-pid" ] && [ -n "$2" ]; then
	build_child_map
	project_for_pid "$2" || printf 'no ddev project'
	echo
	exit 0
fi

emit() {
	local active pairs="" ws pid proj seen=""
	active=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // 0')
	build_child_map

	while read -r ws pid; do
		[ -n "$ws" ] || continue
		case " $seen " in *" $ws "*) continue ;; esac
		proj=$(project_for_pid "$pid") || continue
		[ -n "$proj" ] || continue
		seen="$seen $ws"
		pairs="${pairs}${ws}\t${proj}\n"
	done < <(hyprctl clients -j 2>/dev/null |
		jq -r '.[] | select(.workspace.id > 0) | "\(.workspace.id) \(.pid)"' |
		sort -n)

	printf '%b' "$pairs" | jq -Rrc --slurp --argjson active "${active:-0}" --arg icon "$ICON" '
		[ split("\n")[] | select(length > 0) | split("\t")
		  | { id: (.[0] | tonumber), name: .[1] } ]
		| sort_by(.id)
		| {
			text: (
				map(
					(if .id == $active then "<b>\(.id) \($icon) \(.name)</b>"
					 else "\(.id) \($icon) \(.name)" end)
				) | join("  ")
			),
			tooltip: (
				if length == 0 then "No ddev project in any workspace"
				else (map("Workspace \(.id): \(.name)") | join("\n"))
				end
			),
			class: (if length == 0 then "empty" else "populated" end),
		}'
}

emit

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
		focusedmon\>\>* | movewindowv2\>\>*)
			emit
			;;
	esac
done
