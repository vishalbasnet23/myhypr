-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  --
-- Prints UserConfigs/01-UserDefaults.lua as shell assignments, safely quoted.
-- Used by scripts/UserDefaults.sh; not loaded by Hyprland.

local path = os.getenv("HOME") .. "/.config/hypr/UserConfigs/01-UserDefaults.lua"

local ok, d = pcall(dofile, path)
if not ok or type(d) ~= "table" then
  io.stderr:write("Error: could not load " .. path .. "\n")
  os.exit(1)
end

-- POSIX single-quote escaping: close, insert an escaped quote, reopen.
local function shq(s)
  return "'" .. (tostring(s):gsub("'", "'\\''")) .. "'"
end

for _, k in ipairs({ "term", "files", "edit", "Search_Engine" }) do
  io.write(k, "=", shq(d[k] or ""), "\n")
end
