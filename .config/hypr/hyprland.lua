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

-- Initial boot script enable to apply initial wallpapers, theming, new settings etc.
-- suggest not to change this or delete this including deleting referrence file in ~/.config/hypr/.initial_startup_done
-- as long as the referrence file is present, this initial-boot.sh will not execute
-- NOTE: registered before the Startup_Apps handlers below so it still runs first.
hl.on("hyprland.start", function()
  hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/initial-boot.sh")
end)

-- Sourcing external config files
-- (was: $configs = $HOME/.config/hypr/configs)

require("configs.Keybinds") -- Pre-configured keybinds

-- ## This is where you want to start tinkering
-- (was: $UserConfigs = $HOME/.config/hypr/UserConfigs)

require("UserConfigs.Startup_Apps") -- put your start-up packages on this file

require("UserConfigs.ENVariables") -- Environment variables to load

-- require("UserConfigs.Monitors")       -- Its all about your monitor config (old dots) will remove on push to main
-- require("UserConfigs.WorkspaceRules") -- Hyprland workspaces (old dots) will remove on push to main

require("UserConfigs.Laptops") -- For laptop related

require("UserConfigs.LaptopDisplay") -- Laptop display related. You need to read the comment on this file

require("UserConfigs.WindowRules") -- all about Hyprland Window Rules and Layer Rules

require("UserConfigs.UserDecorations") -- Decorations config file

require("UserConfigs.UserAnimations") -- Animation config file

require("UserConfigs.UserKeybinds") -- Put your own keybinds here

require("UserConfigs.UserSettings") -- Main Hyprland Settings.

-- settings for User defaults apps.
-- MIGRATION NOTE: this module now only RETURNS a table of values (term, files, edit,
-- Search_Engine) and has no side effects, so requiring it here does nothing on its own.
-- It is consumed by UserConfigs/UserKeybinds.lua. Kept for parity with the old
-- `source =` line; safe to delete.
require("UserConfigs.01-UserDefaults")

-- nwg-displays
-- NOTE: nwg-displays already writes these two in Lua form — they were generated
-- alongside the old monitors.conf / workspaces.conf and are now what actually loads.
require("monitors")
require("workspaces")
