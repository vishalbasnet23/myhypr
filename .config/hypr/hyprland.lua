-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  --
-- always refer to Hyprland wiki
-- https://wiki.hypr.land/

-- ============================================================================
-- MIGRATED from hyprland.conf (hyprlang) to the Lua config format.
--
-- Hyprland >= 0.55 loads ~/.config/hypr/hyprland.lua INSTEAD of hyprland.conf
-- whenever the .lua file exists — the two are mutually exclusive and the choice
-- is made once, at startup.
--
-- TO ACTIVATE:  mv ~/.config/hypr/hyprland.lua.new ~/.config/hypr/hyprland.lua
-- TO ROLL BACK: rm ~/.config/hypr/hyprland.lua      (hyprland.conf takes over again)
--
-- All the old .conf files are left untouched, so rollback is just that one rm.
-- ============================================================================

-- MIGRATION NOTE on sourcing: `source = $configs/Keybinds.conf` becomes require().
-- Module names are paths relative to this config directory, with '/' written as '.'
-- and no .lua extension — Hyprland puts <config-dir>/?.lua on package.path.
-- Load ORDER IS PRESERVED EXACTLY, and it matters: window rules apply top-to-bottom,
-- and later hl.config() calls override earlier ones for the same key.

-- ============================================================================
-- ONE-LINE REVERT
--
-- STRICT = true restores the exact pre-port behaviour: plain hard `require` for
-- every module, in this same order, with the `load = false` gates below IGNORED
-- and no failure notification. Any module that errors takes the whole config
-- down again, which is what happened before this loader existed.
--
-- Leave it false for the tolerant loader (a broken or missing module is skipped
-- and reported instead of nuking every bind, rule and autostart).
-- ============================================================================
local STRICT = false

-- Initial boot script enable to apply initial wallpapers, theming, new settings etc.
-- suggest not to change this or delete this including deleting referrence file in ~/.config/hypr/.initial_startup_done
-- as long as the referrence file is present, this initial-boot.sh will not execute
-- NOTE: registered before the Startup_Apps handlers below so it still runs first.
hl.on("hyprland.start", function()
  hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/initial-boot.sh")
end)

-- ============================================================================
-- Load list. Order is the old `source =` order, unchanged — do not reshuffle.
--
-- Flip a `load` to false to skip that file wholesale (the Lua equivalent of
-- commenting out its `source =` line). Useful for bisecting a bad setting:
-- disable, save, Hyprland reloads in ~2s, see what changed.
-- ============================================================================
local modules = {
  -- Sourcing external config files
  -- (was: $configs = $HOME/.config/hypr/configs)
  { mod = "configs.Keybinds", load = true }, -- Pre-configured keybinds

  -- ## This is where you want to start tinkering
  -- (was: $UserConfigs = $HOME/.config/hypr/UserConfigs)
  { mod = "UserConfigs.Startup_Apps", load = true }, -- put your start-up packages on this file
  { mod = "UserConfigs.ENVariables", load = true }, -- Environment variables to load

  -- require("UserConfigs.Monitors")       -- Its all about your monitor config (old dots) will remove on push to main
  -- require("UserConfigs.WorkspaceRules") -- Hyprland workspaces (old dots) will remove on push to main

  { mod = "UserConfigs.Laptops", load = true }, -- For laptop related
  { mod = "UserConfigs.LaptopDisplay", load = true }, -- Laptop display related. You need to read the comment on this file
  { mod = "UserConfigs.WindowRules", load = true }, -- all about Hyprland Window Rules and Layer Rules
  { mod = "UserConfigs.UserDecorations", load = true }, -- Decorations config file
  { mod = "UserConfigs.UserAnimations", load = true }, -- Animation config file
  { mod = "UserConfigs.UserKeybinds", load = true }, -- Put your own keybinds here
  { mod = "UserConfigs.UserSettings", load = true }, -- Main Hyprland Settings.

  -- settings for User defaults apps.
  -- MIGRATION NOTE: this module now only RETURNS a table of values (term, files, edit,
  -- Search_Engine) and has no side effects, so requiring it here does nothing on its own.
  -- It is consumed by UserConfigs/UserKeybinds.lua. Kept for parity with the old
  -- `source =` line; safe to delete.
  { mod = "UserConfigs.01-UserDefaults", load = true },

  -- nwg-displays
  -- NOTE: nwg-displays already writes these two in Lua form — they were generated
  -- alongside the old monitors.conf / workspaces.conf and are now what actually loads.
  -- `optional` because a fresh checkout on a machine nwg-displays has not run on yet
  -- has neither file, and that is not an error worth killing the config over.
  { mod = "monitors", load = true, optional = true },
  { mod = "workspaces", load = true, optional = true },
}

-- Tolerant require. Returns nil + reason instead of aborting the whole config.
local function tryRequire(mod)
  local ok, err = pcall(require, mod)
  if ok then
    return true
  end
  err = tostring(err)
  if err:match("module '.-' not found") then
    return false, "missing"
  end
  return false, err
end

local failures = {}

for _, entry in ipairs(modules) do
  if STRICT then
    require(entry.mod) -- pre-port behaviour: gates ignored, errors are fatal
  elseif entry.load then
    local ok, reason = tryRequire(entry.mod)
    if not ok and not (entry.optional and reason == "missing") then
      failures[#failures + 1] = entry.mod .. " (" .. reason .. ")"
    end
  end
end

-- Say so on screen, otherwise a skipped file just looks like "my keybinds
-- randomly stopped working". hl.notification is in-compositor, so it does not
-- depend on swaync being up yet at config-load time.
if #failures > 0 then
  local text = "hyprland.lua: skipped " .. #failures .. " config file(s):\n" .. table.concat(failures, "\n")
  print("[hyprland.lua] " .. text)
  pcall(function()
    hl.notification.create({ text = text, timeout = 15000 })
  end)
end
