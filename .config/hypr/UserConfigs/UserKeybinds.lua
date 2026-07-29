-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  --
-- This is where you put your own keybinds. Be Mindful to check as well ~/.config/hypr/configs/Keybinds.lua to avoid conflict

-- See https://wiki.hypr.land/Configuring/Basics/Binds/ for more settings and variables
-- See also Laptops.lua for laptops keybinds

-- /* ---- ✴️ Variables ✴️ ---- */  --
local HOME        = os.getenv("HOME")
local mainMod     = "SUPER"
local scriptsDir  = HOME .. "/.config/hypr/scripts"
local UserScripts = HOME .. "/.config/hypr/UserScripts"

-- settings for User defaults apps - set your default terminal and file manager on this file
-- MIGRATION NOTE: `source = $UserConfigs/01-UserDefaults.conf` becomes a require() that
-- returns a table, because hyprlang's global `$term` / `$files` variables have no Lua
-- equivalent. See UserConfigs/01-UserDefaults.lua.
local defaults = require("UserConfigs.01-UserDefaults")
local term  = defaults.term
local files = defaults.files

-- common shortcuts
-- hl.bind(mainMod .. " + SUPER_L", hl.dsp.exec_cmd("pkill rofi || rofi -show drun -modi drun,filebrowser,run,window"), { release = true }) -- Super Key to Launch rofi menu
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("pkill rofi || true && rofi -show drun -modi drun,filebrowser,run,window")) -- Main Menu (APP Launcher)
-- hl.bind(mainMod .. " + B", hl.dsp.exec_cmd('xdg-open "https://"')) -- default browser
-- hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("pkill rofi || true && ags -t 'overview'")) -- desktop overview (if installed)
hl.bind(mainMod .. " + A", hl.dsp.global("quickshell:overviewToggle")) -- desktop overview (if installed)
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(term))                -- terminal
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(files))                    -- file manager
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("brave"))                  -- Launch Firefox
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(scriptsDir .. "/ClipManager.sh")) -- Clipboard Manager
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("obsidian --ozone-platform=x11")) -- Obsidian
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("spotify-launcher"))       -- Spotify

-- FEATURES / EXTRAS
hl.bind(mainMod .. " + ALT + H", hl.dsp.exec_cmd(scriptsDir .. "/KeyHints.sh"))   -- help / cheat sheet
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd(scriptsDir .. "/Refresh.sh"))  -- Refresh waybar, swaync, rofi
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd(scriptsDir .. "/ChangeBlur.sh")) -- Toggle blur settings
-- hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd(scriptsDir .. "/GameMode.sh")) -- Toggle animations ON/OFF
-- hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd(UserScripts .. "/MountGdrive.sh")) -- Mount Gdrive on loccal machine
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd(UserScripts .. "/Toggle-tuned.sh")) -- Toggle animations ON/OFF
-- hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd(UserScripts .. "/SyncDotfiles.sh")) -- Sync dotfiles
-- hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd(UserScripts .. "/RcloneSync.sh")) -- Sync Document folder to google drive
hl.bind(mainMod .. " + ALT + L", hl.dsp.exec_cmd(scriptsDir .. "/ChangeLayout.sh")) -- Toggle Master or Dwindle Layout
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("hyprpicker -a / –autocopy")) -- color picker for hyprland
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("systemd-run --user --scope " .. scriptsDir .. "/parrotOS-KVM.sh")) -- start yazi in foot
-- hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("/home/ahmad/Documents/blog/quickScript.sh")) -- Hugo file sync
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.window.fullscreen())                          -- whole full screen
hl.bind(mainMod .. " + M", hl.dsp.window.fullscreen({ mode = "maximized" }))            -- fake full screen
hl.bind(mainMod .. " + SPACE", hl.dsp.window.float({ action = "toggle" }))               -- Float Mode

-- DEPRECATED: the `workspaceopt` dispatcher (used as `hyprctl dispatch workspaceopt
-- allfloat`) is not in the 0.55+ dispatcher list and has no documented replacement.
-- The bind is preserved verbatim so nothing is silently dropped, but it will no-op
-- until you pick a replacement. See the migration report.
hl.bind(mainMod .. " + ALT + SPACE", hl.dsp.exec_cmd("hyprctl dispatch workspaceopt allfloat")) -- All Float Mode

hl.bind(mainMod .. " + ALT + E", hl.dsp.exec_cmd(scriptsDir .. "/RofiEmoji.sh")) -- emoji menu


-- Desktop zooming or magnifier
-- MIGRATION NOTE: the original shelled out to
--   hyprctl keyword cursor:zoom_factor "$(hyprctl getoption cursor:zoom_factor | awk ...)"
-- `hyprctl keyword` speaks hyprlang and is not the right tool against a Lua config, so
-- this is now done natively with hl.get_config() + hl.config(). Same behaviour: clamp the
-- current factor to a minimum of 1, then double or halve it.
local function zoomBy(multiplier)
  return function()
    local factor = tonumber(hl.get_config("cursor.zoom_factor")) or 1
    if factor < 1 then factor = 1 end
    hl.config({ cursor = { zoom_factor = factor * multiplier } })
  end
end

hl.bind(mainMod .. " + ALT + mouse_down", zoomBy(2.0))
hl.bind(mainMod .. " + ALT + mouse_up",   zoomBy(0.5))

-- NOTES for ja (Hyprland version 0.39 (Ubuntu 24.04))
-- misc:cursor_zoom_factor was the pre-0.40 name for cursor:zoom_factor; not applicable here.

-- Waybar / Bar related
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("pkill -SIGUSR1 waybar"))            -- Toggle hide/show waybar
hl.bind(mainMod .. " + CTRL + B", hl.dsp.exec_cmd(scriptsDir .. "/WaybarStyles.sh"))    -- Waybar Styles Menu
hl.bind(mainMod .. " + ALT + B", hl.dsp.exec_cmd(scriptsDir .. "/WaybarLayout.sh"))     -- Waybar Layout Menu

-- FEATURES / EXTRAS (UserScripts)
hl.bind(mainMod .. " + ALT + M", hl.dsp.exec_cmd(UserScripts .. "/RofiBeats.sh"))       -- online music using rofi
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(UserScripts .. "/WallpaperSelect.sh")) -- Select wallpaper to apply
-- hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(UserScripts .. "/WallpaperEffects.sh")) -- Wallpaper Effects by imagemagick
hl.bind("CTRL + ALT + W", hl.dsp.exec_cmd(UserScripts .. "/WallpaperRandom.sh"))        -- Random wallpapers

-- MIGRATION NOTE: `exec, hyprctl setprop active opaque toggle` becomes the native
-- set_prop dispatcher. Props are the dynamic window-rule effects.
-- Flagged in the migration report: the "toggle" value for a boolean prop is not
-- explicitly documented, so confirm this one behaves as before.
hl.bind(mainMod .. " + CTRL + O", hl.dsp.window.set_prop({ prop = "opaque", value = "toggle" })) -- disable opacity on active window

hl.bind(mainMod .. " + ALT + K", hl.dsp.exec_cmd(scriptsDir .. "/KeyBinds.sh"))         -- search keybinds via rofi
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd(scriptsDir .. "/Animations.sh"))     -- hyprland animations menu
hl.bind(mainMod .. " + SHIFT + Z", hl.dsp.exec_cmd(UserScripts .. "/ZshChangeTheme.sh")) -- Change oh-my-zsh theme
-- hl.bind("ALT_L + SHIFT_L", hl.dsp.exec_cmd(scriptsDir .. "/SwitchKeyboardLayout.sh"), { locked = true, non_consuming = true }) -- Change keyboard layout globally
-- hl.bind("SHIFT_L + ALT_L", hl.dsp.exec_cmd(scriptsDir .. "/Tak0-Per-Window-Switch.sh"), { locked = true, non_consuming = true }) -- Change keyboard layout locally for each window
hl.bind(mainMod .. " + CTRL + C", hl.dsp.exec_cmd(UserScripts .. "/RofiCalc.sh"))       -- calculator (qalculate)

-- Move focus with mainMod + arrow keys
-- NOTE (pre-existing conflict, preserved as-is): SUPER + j/k here collide with the
-- SUPER + J/K layout binds in configs/Keybinds.lua — Hyprland treats the letter case
-- the same. This was already true in your .conf.
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "d" }))

-- Resize windows
hl.bind(mainMod .. " + SHIFT + h", hl.dsp.window.resize({ x = -50, y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.window.resize({ x = 50,  y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.window.resize({ x = 0,   y = -50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + j", hl.dsp.window.resize({ x = 0,   y = 50,  relative = true }), { repeating = true })

-- Move windows
-- NOTE (pre-existing oddity, preserved as-is): `l` maps to direction "l" and `h` maps
-- to direction "r" here — that looks inverted versus the focus binds above, but it is
-- exactly what your .conf had.
hl.bind(mainMod .. " + CTRL + l", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + CTRL + h", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + CTRL + k", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + CTRL + j", hl.dsp.window.move({ direction = "d" }))

-- Swap windows
-- NOTE (pre-existing duplicate, preserved as-is): these four are byte-for-byte repeats
-- of the swap binds in configs/Keybinds.lua.
hl.bind(mainMod .. " + ALT + left",  hl.dsp.window.swap({ direction = "l" }))
hl.bind(mainMod .. " + ALT + right", hl.dsp.window.swap({ direction = "r" }))
hl.bind(mainMod .. " + ALT + up",    hl.dsp.window.swap({ direction = "u" }))
hl.bind(mainMod .. " + ALT + down",  hl.dsp.window.swap({ direction = "d" }))


-- For passthrough keyboard into a VM
-- MIGRATION NOTE: submaps are now blocks, not `submap = name` / `submap = reset` markers:
-- hl.bind(mainMod .. " + ALT + P", hl.dsp.submap("passthru"))
-- hl.define_submap("passthru", function()
--   -- to unbind
--   hl.bind(mainMod .. " + ALT + P", hl.dsp.submap("reset"))
-- end)


-- Removed One
-- hl.bind(mainMod .. " + S", hl.dsp.exec_cmd(scriptsDir .. "/RofiSearch.sh")) -- Google search using rofi
-- hl.bind(mainMod .. " + CTRL + R", hl.dsp.exec_cmd(scriptsDir .. "/RofiThemeSelector.sh")) -- KooL Rofi Menu Theme Selector
-- hl.bind(mainMod .. " + CTRL + SHIFT + R", hl.dsp.exec_cmd("pkill rofi || true && " .. scriptsDir .. "/RofiThemeSelector-modified.sh")) -- modified Rofi Theme Selector
