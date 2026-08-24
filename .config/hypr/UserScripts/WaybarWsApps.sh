#!/bin/bash
# Waybar custom module: one icon per workspace for that workspace's main app.
#   1   2   3 󰨞
# Quieter than "hyprland/workspaces#rw", which lists every window. "Main app" is
# the workspace's most recently focused window (lowest focusHistoryID), falling
# back to the first one Hyprland reports.
# Long-running: emits on Hyprland events instead of polling.
# Glyphs are a subset of the window-rewrite table in waybar/ModulesWorkspaces.

SOCKET="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
[ -S "$SOCKET" ] || exit 0

# class regex -> glyph. First match wins, so order matters.
read -r -d '' ICONS <<'JQ'
[
  ["^(firefox|org\\.mozilla\\.firefox|librewolf|floorp|[Cc]achy-browser)$", ""],
  ["^zen", "󰰷"],
  ["^(brave-browser)$", ""],
  ["^(Chromium|Thorium|[Cc]hrome|chromium)$", ""],
  ["^(microsoft-edge)$", ""],
  ["^(kitty|konsole|kitty-dropterm)$", ""],
  ["^(com\\.mitchellh\\.ghostty)$", ""],
  ["^(org\\.wezfurlong\\.wezterm)$", ""],
  ["^([Tt]hunderbird)", ""],
  ["^([Tt]elegram-desktop|org\\.telegram\\.desktop)$", ""],
  ["^(discord|[Ww]ebcord|Vesktop)$", ""],
  ["^(slack)$", ""],
  ["^(mpv)$", ""],
  ["^(vlc)$", "󰕼"],
  ["^([Ss]potify)$", ""],
  ["^(Cider)$", "󰎆"],
  ["^(VSCode|code-url-handler|code-oss|codium|VSCodium)$", "󰨞"],
  ["^(dev\\.zed\\.Zed)$", "󰵁"],
  ["^(jetbrains-idea)$", ""],
  ["^(subl)$", "󰅳"],
  ["^(thunar|nemo)$", "󰝰"],
  ["^(steam)$", ""],
  ["^(gimp)$", ""],
  ["^(virt-manager|\\.virt-manager-wrapped|virt-viewer)$", ""],
  ["^(obs|com\\.obsproject\\.Studio)$", ""],
  ["^(libreoffice-writer)$", ""],
  ["^(libreoffice-calc)$", ""],
  ["^([Oo]bsidian)$", ""],
  ["^([Pp]avucontrol|org\\.pulseaudio\\.pavucontrol)$", "󱡫"]
]
JQ

emit() {
	local active
	active=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // 0')
	hyprctl clients -j 2>/dev/null | jq -rc \
		--argjson active "${active:-0}" \
		--argjson icons "$ICONS" '
		# Bind the class before walking $icons, else the inner "." is an
		# $icons row and .class no longer resolves.
		def icon(c):
			(c) as $c
			| ( [ $icons[] as $row | select($c | test($row[0])) | $row[1] ] | .[0] ) // "";

		[ .[] | select(.workspace.id > 0) ]
		| group_by(.workspace.id)
		| map(
			( . | sort_by(.focusHistoryID) | .[0] ) as $main
			| { id: $main.workspace.id, cls: $main.class, n: length }
		)
		| sort_by(.id)
		| {
			text: (
				map(
					(if .id == $active then "<b>\(.id) \(icon(.cls))</b>"
					 else "\(.id) \(icon(.cls))" end)
				) | join("  ")
			),
			tooltip: (
				if length == 0 then "No windows open"
				else (map("Workspace \(.id): \(.cls)"
					+ (if .n > 1 then " (+\(.n - 1) more)" else "" end)) | join("\n"))
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
		activewindow\>\>* | focusedmon\>\>* | movewindowv2\>\>*)
			emit
			;;
	esac
done
