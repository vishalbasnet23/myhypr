-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  --

-- See https://wiki.hypr.land/Configuring/Basics/Binds/ for more variable settings
-- These configs are mostly for laptops. This is addemdum to configs/Keybinds.lua

local HOME       = os.getenv("HOME")
local mainMod    = "SUPER"
local scriptsDir = HOME .. "/.config/hypr/scripts"

-- for disabling Touchpad. hyprctl devices to get device name.
local Touchpad_Device = "asue1209:00-04f3:319f-touchpad"

-- MIGRATION NOTE on bind flags:
--   binde  ->  { repeating = true }
--   bindl  ->  { locked = true }
--   bindel ->  { repeating = true, locked = true }
--   bindm  ->  { mouse = true }
-- Keysyms are also written in their canonical XKB spelling (xf86... -> XF86...);
-- the old lowercase forms were accepted case-insensitively, canonical is safer.

hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd(scriptsDir .. "/BrightnessKbd.sh --dec"), { repeating = true }) -- decrease keyboard brightness
hl.bind("XF86KbdBrightnessUp",   hl.dsp.exec_cmd(scriptsDir .. "/BrightnessKbd.sh --inc"), { repeating = true }) -- increase keyboard brightness
hl.bind("XF86Launch1", hl.dsp.exec_cmd("rog-control-center"))    -- ASUS Armory crate button
hl.bind("XF86Launch3", hl.dsp.exec_cmd("asusctl led-mode -n"))   -- FN+F4 Switch keyboard RGB profile
hl.bind("XF86Launch4", hl.dsp.exec_cmd("asusctl profile -n"))    -- FN+F5 change of fan profiles (Quite, Balance, Performance)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(scriptsDir .. "/Brightness.sh --dec"), { repeating = true }) -- decrease monitor brightness
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(scriptsDir .. "/Brightness.sh --inc"), { repeating = true }) -- increase monitor brightness
hl.bind("XF86TouchpadToggle", hl.dsp.exec_cmd(scriptsDir .. "/TouchPad.sh")) -- disable touchpad
-- ^^ SEE MIGRATION REPORT: TouchPad.sh toggles the hyprlang variable $TOUCHPAD_ENABLED
--    via `hyprctl keyword`. hyprlang variables do not exist in the Lua config, so this
--    script needs rewriting before this bind does anything.

-- Screenshot keybindings using F6 (no PrinSrc button)
hl.bind(mainMod .. " + F6",           hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --now"))   -- screenshot
hl.bind(mainMod .. " + SHIFT + F6",   hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --area"))  -- screenshot (area)
hl.bind(mainMod .. " + CTRL + F6",    hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in5"))   -- screenshot (5 secs delay)
hl.bind(mainMod .. " + ALT + F6",     hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in10"))  -- screenshot (10 secs delay)
hl.bind("ALT + F6",                   hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --active")) -- screenshot (active window only)

-- MIGRATION NOTE: `$TOUCHPAD_ENABLED = true` + a `device { }` block becomes a plain
-- Lua local + hl.device(). Per-device options live in the same table as the name.
local TOUCHPAD_ENABLED = true
hl.device({
  name    = Touchpad_Device,
  enabled = TOUCHPAD_ENABLED,
})

-- Below are useful when you are connecting your laptop in external display
-- Suggest you edit below for your laptop display
-- From WIKI This is to disable laptop monitor when lid is closed.
-- consult https://wiki.hypr.land/Configuring/Basics/Binds/#switches
-- hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("hyprctl keyword monitor \"eDP-1, preferred, auto, 1\""), { locked = true })
-- hl.bind("switch:on:Lid Switch",  hl.dsp.exec_cmd("hyprctl keyword monitor \"eDP-1, disable\""), { locked = true })

-- WARNING! Using this method has some caveats!! USE THIS PART WITH SOME CAUTION!
-- CONS of doing this, is that you need to set up your wallpaper (SUPER W) and choose wallpaper.
-- CAVEATS! Sometimes the Main Laptop Monitor DOES NOT have display that it needs to re-connect your external monitor
-- One work around is to ensure that before shutting down laptop, MAKE SURE your laptop lid is OPEN!!
-- Make sure to comment (put -- on the both the switch binds) above
-- NOTE: Display for laptop are being generated into LaptopDisplay.lua
-- This part is to be use if you do not want your main laptop monitor to wake up during say wallpaper change etc

-- hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("echo 'hl.monitor({ output = \"eDP-1\", mode = \"preferred\", position = \"auto\", scale = 1 })' > " .. HOME .. "/.config/hypr/UserConfigs/LaptopDisplay.lua"), { locked = true })
-- hl.bind("switch:on:Lid Switch",  hl.dsp.exec_cmd("echo 'hl.monitor({ output = \"eDP-1\", disabled = true })' > " .. HOME .. "/.config/hypr/UserConfigs/LaptopDisplay.lua"), { locked = true })

-- for laptop-lid action (to erase the last entry)
-- hl.on("hyprland.start", function()
--   hl.exec_cmd("echo 'hl.monitor({ output = \"eDP-1\", mode = \"preferred\", position = \"auto\", scale = 1 })' > " .. HOME .. "/.config/hypr/UserConfigs/LaptopDisplay.lua")
-- end)
