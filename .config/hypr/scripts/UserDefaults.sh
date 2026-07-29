#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Shared helper: exposes the values from UserConfigs/01-UserDefaults.lua to shell scripts.
#
# Replaces the old hack of `sed 's/\$//g' 01-UserDefaults.conf | eval`, which relied on
# hyprlang's `$var = value` lines happening to look like shell assignments. The Lua file
# returns a table instead, so we ask Lua for the values (see user-defaults-emit.lua)
# and eval the shell-quoted output.
#
# Usage:  source "$HOME/.config/hypr/scripts/UserDefaults.sh"
#         -> sets $term $files $edit $Search_Engine

_hypr_defaults_file="$HOME/.config/hypr/UserConfigs/01-UserDefaults.lua"
_hypr_emitter="$HOME/.config/hypr/scripts/user-defaults-emit.lua"

if [[ ! -f "$_hypr_defaults_file" ]]; then
  echo "Error: $_hypr_defaults_file not found!" >&2
  return 1 2>/dev/null || exit 1
fi

_hypr_lua=$(command -v lua5.5 || command -v lua || command -v lua5.4 || command -v luajit)
if [[ -z "$_hypr_lua" ]]; then
  echo "Error: no lua interpreter found (need lua5.5, lua, lua5.4 or luajit)" >&2
  return 1 2>/dev/null || exit 1
fi

if ! _hypr_defaults_out=$("$_hypr_lua" "$_hypr_emitter"); then
  echo "Error: failed to read defaults from $_hypr_defaults_file" >&2
  return 1 2>/dev/null || exit 1
fi

eval "$_hypr_defaults_out"
unset _hypr_defaults_file _hypr_emitter _hypr_lua _hypr_defaults_out
