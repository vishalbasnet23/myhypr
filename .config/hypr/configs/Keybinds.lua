-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  --
-- Default Keybinds
-- visit https://wiki.hypr.land/Configuring/Basics/Binds/ for more info

-- MIGRATION NOTES for this whole file:
--  * `bind = MODS, KEY, dispatcher, arg` becomes hl.bind("MODS + KEY", hl.dsp.<dispatcher>(arg)).
--    Mods and key are one "+"-joined string; a leading empty mod field just disappears.
--  * Bind-flag suffixes become an options table:
--      binde  -> { repeating = true }
--      bindl  -> { locked = true }
--      bindel -> { repeating = true, locked = true }
--      bindm  -> { mouse = true }
--  * Dispatcher renames used below:
--      killactive             -> hl.dsp.window.close()
--      exec                   -> hl.dsp.exec_cmd()
--      layoutmsg <msg>        -> hl.dsp.layout("<msg>")
--      cyclenext              -> hl.dsp.window.cycle_next()
--      resizeactive X Y       -> hl.dsp.window.resize({ x, y, relative = true })
--      movewindow <dir>       -> hl.dsp.window.move({ direction })
--      swapwindow <dir>       -> hl.dsp.window.swap({ direction })
--      movefocus <dir>        -> hl.dsp.focus({ direction })
--      workspace <sel>        -> hl.dsp.focus({ workspace })
--      movetoworkspace        -> hl.dsp.window.move({ workspace, follow = true })
--      movetoworkspacesilent  -> hl.dsp.window.move({ workspace, follow = false })
--      togglespecialworkspace -> hl.dsp.workspace.toggle_special()
--      movewindow   (bindm)   -> hl.dsp.window.drag()
--      resizewindow (bindm)   -> hl.dsp.window.resize()
--    `follow` is written explicitly on both move variants because its default is
--    not documented, and that default is the whole difference between the two.
--  * Keysyms are written in canonical XKB spelling (xf86audiomute -> XF86AudioMute).

-- /* ---- ✴️ Variables ✴️ ---- */  --
local HOME        = os.getenv("HOME")
local mainMod     = "SUPER"
local scriptsDir  = HOME .. "/.config/hypr/scripts"
local UserScripts = HOME .. "/.config/hypr/UserScripts" -- declared in the original, unused here

-- MIGRATION NOTE: `exec, hyprctl dispatch exit 0` is now the exit dispatcher directly.
-- See the migration report: if you ever move to uwsm, replace this with
-- hl.dsp.exec_cmd("uwsm stop") — the wiki warns against exit under uwsm.
hl.bind("CTRL + ALT + Delete", hl.dsp.exit())                                              -- exit Hyprland
hl.bind(mainMod .. " + Q", hl.dsp.window.close())                                          -- close active (not kill)
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd(scriptsDir .. "/KillActiveProcess.sh"))  -- Kill active process
hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd(scriptsDir .. "/LockScreen.sh"))                 -- screen lock
hl.bind("CTRL + ALT + P", hl.dsp.exec_cmd(scriptsDir .. "/Wlogout.sh"))                    -- power menu
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("swaync-client -t -sw"))                        -- swayNC notification panel
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd(scriptsDir .. "/Kool_Quick_Settings.sh")) -- Settings Menu KooL Hyprland Settings

-- Master Layout
hl.bind(mainMod .. " + CTRL + D", hl.dsp.layout("removemaster"))
hl.bind(mainMod .. " + I", hl.dsp.layout("addmaster"))
hl.bind(mainMod .. " + J", hl.dsp.layout("cyclenext"))
hl.bind(mainMod .. " + K", hl.dsp.layout("cycleprev"))
hl.bind(mainMod .. " + CTRL + Return", hl.dsp.layout("swapwithmaster"))

-- Dwindle Layout
-- hl.bind(mainMod .. " + SHIFT + I", hl.dsp.layout("togglesplit")) -- only works on dwindle layout
-- hl.bind(mainMod .. " + P", hl.dsp.window.pseudo()) -- dwindle

-- Works on either layout (Master or Dwindle)
-- hl.bind(mainMod .. " + M", hl.dsp.layout("splitratio 0.3"))

-- group
-- hl.bind(mainMod .. " + G", hl.dsp.group.toggle()) -- toggle group
-- hl.bind(mainMod .. " + CTRL + tab", hl.dsp.group.next()) -- change focus to another window

-- Cycle windows if floating bring to top
-- NOTE (pre-existing conflict, preserved as-is): this re-binds SUPER + J, which is
-- already bound to layout("cyclenext") above. It was a duplicate in your .conf too.
hl.bind(mainMod .. " + J", hl.dsp.window.cycle_next())
-- hl.bind("ALT + tab", hl.dsp.window.bring_to_top())

-- Special Keys / Hot Keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --inc"), { repeating = true, locked = true })       -- volume up
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --dec"), { repeating = true, locked = true })       -- volume down
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --toggle-mic"), { locked = true })                      -- mic mute
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --toggle"), { locked = true })                             -- mute
hl.bind("XF86Sleep", hl.dsp.exec_cmd("systemctl suspend"), { locked = true })                                                -- sleep button
hl.bind("XF86RFKill", hl.dsp.exec_cmd(scriptsDir .. "/AirplaneMode.sh"), { locked = true })                                  -- Airplane mode

-- media controls using keyboards
-- INVALID KEYSYM (pre-existing, was dead in your .conf too): there is no
-- `XF86AudioPlayPause` keysym in xkbcommon — only XF86AudioPlay and XF86AudioPause,
-- both of which are bound below and both already run `--pause`. Under hyprlang this
-- line failed quietly; under Lua hl.bind raises, so it is commented out rather than
-- left to throw. Nothing is lost functionally.
-- hl.bind("XF86AudioPlayPause", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --pause"), { locked = true })
hl.bind("XF86AudioPause",     hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --pause"), { locked = true })
hl.bind("XF86AudioPlay",      hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --pause"), { locked = true })
hl.bind("XF86AudioNext",      hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --nxt"),   { locked = true })
hl.bind("XF86AudioPrev",      hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --prv"),   { locked = true })
hl.bind("XF86AudioStop",      hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --stop"),  { locked = true })

-- Screenshot keybindings NOTE: You may need to press Fn key as well
hl.bind(mainMod .. " + Print",              hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --now"))    -- screenshot
hl.bind(mainMod .. " + SHIFT + Print",      hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --area"))   -- screenshot (area)
hl.bind(mainMod .. " + CTRL + Print",       hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in5"))    -- screenshot (5 secs delay)
hl.bind(mainMod .. " + CTRL + SHIFT + Print", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in10")) -- screenshot (10 secs delay)
hl.bind("ALT + Print",                      hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --active")) -- screenshot (active window only)

-- screenshot with swappy (another screenshot tool)
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --swappy")) -- screenshot (swappy)

-- Resize windows
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.resize({ x = -50, y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 50,  y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.resize({ x = 0,   y = -50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.resize({ x = 0,   y = 50,  relative = true }), { repeating = true })

-- Move windows
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.move({ direction = "d" }))

-- Swap windows
hl.bind(mainMod .. " + ALT + left",  hl.dsp.window.swap({ direction = "l" }))
hl.bind(mainMod .. " + ALT + right", hl.dsp.window.swap({ direction = "r" }))
hl.bind(mainMod .. " + ALT + up",    hl.dsp.window.swap({ direction = "u" }))
hl.bind(mainMod .. " + ALT + down",  hl.dsp.window.swap({ direction = "d" }))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "d" }))

-- Workspaces related
hl.bind(mainMod .. " + tab",           hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + SHIFT + tab",   hl.dsp.focus({ workspace = "m-1" }))

-- Special workspace
-- hl.bind(mainMod .. " + SHIFT + U", hl.dsp.window.move({ workspace = "special", follow = true }))
-- hl.bind(mainMod .. " + U", hl.dsp.workspace.toggle_special())
hl.bind(mainMod .. " + U", hl.dsp.workspace.toggle_special("nyx"))
hl.bind(mainMod .. " + SHIFT + U", hl.dsp.window.move({ workspace = "special:nyx", follow = true }))


-- The following mappings use the key codes to better support various keyboard layouts
-- 1 is code:10, 2 is code 11, etc
-- MIGRATION NOTE: the original had these written out as 30 individual lines. Expressed
-- as a loop here (the shipped example config does the same); every one of the 30 binds
-- is still created, with identical mods, keycodes and targets.
--   code:10 = key 1 ... code:18 = key 9, code:19 = key 0 -> workspace 10
for ws = 1, 10 do
  local code = "code:" .. (ws + 9)

  -- Switch workspaces with mainMod + [0-9]
  hl.bind(mainMod .. " + " .. code, hl.dsp.focus({ workspace = ws }))

  -- Move active window and follow to workspace mainMod + SHIFT [0-9]
  hl.bind(mainMod .. " + SHIFT + " .. code, hl.dsp.window.move({ workspace = ws, follow = true }))

  -- Move active window to a workspace silently mainMod + CTRL [0-9]
  hl.bind(mainMod .. " + CTRL + " .. code, hl.dsp.window.move({ workspace = ws, follow = false }))
end

hl.bind(mainMod .. " + SHIFT + bracketleft",  hl.dsp.window.move({ workspace = "-1", follow = true }))  -- brackets [
hl.bind(mainMod .. " + SHIFT + bracketright", hl.dsp.window.move({ workspace = "+1", follow = true }))  -- brackets ]

hl.bind(mainMod .. " + CTRL + bracketleft",   hl.dsp.window.move({ workspace = "-1", follow = false })) -- brackets [
hl.bind(mainMod .. " + CTRL + bracketright",  hl.dsp.window.move({ workspace = "+1", follow = false })) -- brackets ]

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + period",     hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + comma",      hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true }) -- NOTE: mouse:272 = left click
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true }) -- NOTE: mouse:273 = right click
