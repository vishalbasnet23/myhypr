-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  --
-- For window rules and layerrules
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/ for more

-- NOTES: Migrated from the `windowrule = match:... , effect` hyprlang syntax to Lua.
--
-- MIGRATION NOTES for this whole file:
--  * `match:class ^(foo)$` becomes  match = { class = "^(foo)$" }
--    Multiple `match:` props on one line become multiple keys in the same match table.
--  * `<effect> on` becomes  <effect> = true
--  * `move`/`size` took percentages in hyprlang (`size 25% 55%`). The Lua form takes a
--    table of two numbers or two *expression strings*; percentages are not documented,
--    so each one is written as an explicit monitor-relative expression
--    (`25%` -> "monitor_w*0.25"). Same reference frame, same result — but see the
--    migration report, this is worth a visual check.
--  * EVERY rule here is deliberately left ANONYMOUS (no `name =` field). Named rules
--    are evaluated BEFORE all anonymous ones, so naming any of these would silently
--    change the top-to-bottom precedence your config relies on.

-- windowrule - tags - add apps under appropriate tag to use the same settings
-- browser tags
hl.window_rule({ match = { class = "^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr|[Ff]irefox-bin)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^(chrome-.+-Default)$" }, tag = "+browser" }) -- Chrome PWAs
-- hl.window_rule({ match = { class = "^([Cc]hromium)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^([Mm]icrosoft-edge(-stable|-beta|-dev|-unstable))$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^(Brave-browser(-beta|-dev|-unstable)?)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^([Tt]horium-browser|[Cc]achy-browser)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^(zen-alpha|zen)$" }, tag = "+browser" })

-- notif tags
hl.window_rule({ match = { class = "^(swaync-control-center|swaync-notification-window|swaync-client|class)$" }, tag = "+notif" })

-- KooL settings tag
hl.window_rule({ match = { title = "^(KooL Quick Cheat Sheet)$" }, tag = "+KooL_Cheat" })
hl.window_rule({ match = { title = "^(KooL Hyprland Settings)$" }, tag = "+KooL_Settings" })
hl.window_rule({ match = { class = "^(nwg-displays|nwg-look)$" }, tag = "+KooL-Settings" })

-- terminal tags
hl.window_rule({ match = { class = "^(Alacritty|kitty|kitty-dropterm)$" }, tag = "+terminal" })

-- email tags
hl.window_rule({ match = { class = "^([Tt]hunderbird|org.gnome.Evolution)$" }, tag = "+email" })
hl.window_rule({ match = { class = "^(eu.betterbird.Betterbird)$" }, tag = "+email" })

-- project tags
hl.window_rule({ match = { class = "^(codium|codium-url-handler|VSCodium)$" }, tag = "+projects" })
hl.window_rule({ match = { class = "^(VSCode|code-url-handler)$" }, tag = "+projects" })
hl.window_rule({ match = { class = "^(jetbrains-.+)$" }, tag = "+projects" }) -- JetBrains IDEs

-- screenshare tags
hl.window_rule({ match = { class = "^(com.obsproject.Studio)$" }, tag = "+screenshare" })

-- IM tags
-- hl.window_rule({ match = { class = "^([Dd]iscord|[Ww]ebCord|[Vv]esktop)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^([Ww]hatsapp-for-linux)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^(ZapZap|com.rtosta.zapzap)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^(teams-for-linux)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^(im.riot.Riot|Element)$" }, tag = "+im" }) -- Element Matrix client

-- game tags
hl.window_rule({ match = { class = "^(gamescope)$" }, tag = "+games" })
hl.window_rule({ match = { class = "^(steam_app_\\d+)$" }, tag = "+games" })

-- gamestore tags
hl.window_rule({ match = { class = "^([Ss]team)$" }, tag = "+gamestore" })
hl.window_rule({ match = { title = "^([Ll]utris)$" }, tag = "+gamestore" })
hl.window_rule({ match = { class = "^(com.heroicgameslauncher.hgl)$" }, tag = "+gamestore" })

-- file-manager tags
hl.window_rule({ match = { class = "^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt)$" }, tag = "+file-manager" })
hl.window_rule({ match = { class = "^(app.drey.Warp)$" }, tag = "+file-manager" })

-- wallpaper tags
hl.window_rule({ match = { class = "^([Ww]aytrogen)$" }, tag = "+wallpaper" })

-- multimedia tags
hl.window_rule({ match = { class = "^([Aa]udacious)$" }, tag = "+multimedia" })

-- multimedia-video tags
hl.window_rule({ match = { class = "^([Mm]pv|vlc)$" }, tag = "+multimedia_video" })

-- settings tags
hl.window_rule({ match = { title = "^(ROG Control)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(wihotspot(-gui)?)$" }, tag = "+settings" }) -- wifi hotspot
hl.window_rule({ match = { class = "^([Bb]aobab|org.gnome.[Bb]aobab)$" }, tag = "+settings" }) -- Disk usage analyzer
hl.window_rule({ match = { class = "^(gnome-disks|wihotspot(-gui)?)$" }, tag = "+settings" })
hl.window_rule({ match = { title = "(Kvantum Manager)" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(file-roller|org.gnome.FileRoller)$" }, tag = "+settings" }) -- archive manager
hl.window_rule({ match = { class = "^(nm-applet|nm-connection-editor|blueman-manager)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(qt5ct|qt6ct|[Yy]ad)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "(xdg-desktop-portal-gtk)" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^([Rr]ofi)$" }, tag = "+settings" })

-- viewer tags
hl.window_rule({ match = { class = "^(gnome-system-monitor|org.gnome.SystemMonitor|io.missioncenter.MissionCenter)$" }, tag = "+viewer" }) -- system monitor
hl.window_rule({ match = { class = "^(evince)$" }, tag = "+viewer" }) -- document viewer
hl.window_rule({ match = { class = "^(eog|org.gnome.Loupe)$" }, tag = "+viewer" }) -- image viewer


-- Custom rules
hl.window_rule({ match = { class = "^([Cc]hromium)$" }, tile = true })
hl.window_rule({ match = { class = "^(com.network.manager)$" }, size = { "monitor_w*0.25", "monitor_h*0.55" } })
hl.window_rule({ match = { class = "^(com.network.manager)$" }, float = true })
hl.window_rule({ match = { class = "^([Vv]esktop|[Dd]iscord|[Ss]potify)$" }, workspace = "special:nyx" })

-- Some special override rules
hl.window_rule({ match = { tag = "multimedia_video" }, no_blur = true })
hl.window_rule({ match = { tag = "multimedia_video" }, opacity = "1.0" })


-- POSITION
-- hl.window_rule({ match = { float = true }, center = true }) -- warning, it causes even the menu to float and center.
hl.window_rule({ match = { tag = "KooL_Cheat" }, center = true })
-- FIXED (was broken before the migration too): the original title regex used a negative
-- lookahead `^((?!.*[Tt]hunar).)*$`. Hyprland matches with Google RE2, which has no
-- lookahead support — it logged "invalid perl operator: (?!" and the prop never matched.
-- The supported way to negate is the `negative:` prefix, so "title does not contain
-- Thunar" is written as below. Same for the four other lookahead rules in this file.
hl.window_rule({ match = { class = "^([Tt]hunar)$", title = "negative:[Tt]hunar" }, center = true })
hl.window_rule({ match = { title = "^(ROG Control)$" }, center = true })
hl.window_rule({ match = { tag = "KooL-Settings" }, center = true })
hl.window_rule({ match = { title = "^(Keybindings)$" }, center = true })
hl.window_rule({ match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$" }, center = true })
hl.window_rule({ match = { class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$" }, center = true })
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, center = true })
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, move = { "monitor_w*0.61", "monitor_h*0.07" } })
-- hl.window_rule({ match = { title = "^(Firefox)$" }, move = { "monitor_w*0.72", "monitor_h*0.07" } })

-- windowrule to avoid idle for fullscreen apps
-- hl.window_rule({ match = { class = "^(.*)$" }, idle_inhibit = "fullscreen" })
-- hl.window_rule({ match = { title = "^(.*)$" }, idle_inhibit = "fullscreen" })
hl.window_rule({ match = { fullscreen = true }, idle_inhibit = "fullscreen" })

-- windowrule move to workspace
hl.window_rule({ match = { tag = "projects" }, workspace = "1" })
hl.window_rule({ match = { tag = "email" }, workspace = "1" })
hl.window_rule({ match = { tag = "browser" }, workspace = "2" })
hl.window_rule({ match = { class = "^([Tt]hunar)$" }, workspace = "3" })
hl.window_rule({ match = { tag = "im" }, workspace = "4" })
hl.window_rule({ match = { tag = "gamestore" }, workspace = "5" })
hl.window_rule({ match = { tag = "games" }, workspace = "8" })
hl.window_rule({ match = { class = "^(kitty)$", title = "^(tmuxifier)$" }, workspace = "1" })
hl.window_rule({ match = { class = "^(virt-viewer)$" }, workspace = "9" })
hl.window_rule({ match = { class = "^([Oo]bsidian)$" }, workspace = "10" })

-- windowrule move to workspace (silent)
-- MIGRATION NOTE: the `silent` suffix is still a suffix on the workspace string.
hl.window_rule({ match = { tag = "screenshare" }, workspace = "4 silent" })
hl.window_rule({ match = { class = "^(virt-manager)$" }, workspace = "9 silent" })
hl.window_rule({ match = { class = "^(.virt-manager-wrapped)$" }, workspace = "9 silent" })
hl.window_rule({ match = { tag = "multimedia" }, workspace = "9 silent" })

-- FLOAT
hl.window_rule({ match = { tag = "KooL_Cheat" }, float = true })
hl.window_rule({ match = { tag = "wallpaper" }, float = true })
hl.window_rule({ match = { tag = "settings" }, float = true })
hl.window_rule({ match = { tag = "viewer" }, float = true })
hl.window_rule({ match = { tag = "KooL-Settings" }, float = true })
hl.window_rule({ match = { class = "^([Zz]oom|onedriver|onedriver-launcher)$" }, float = true })
hl.window_rule({ match = { class = "^(org.gnome.Calculator)$", title = "^(Calculator)$" }, float = true })
hl.window_rule({ match = { class = "^(mpv|com.github.rafostar.Clapper)$" }, float = true })
hl.window_rule({ match = { class = "^([Qq]alculate-gtk)$" }, float = true })
-- hl.window_rule({ match = { class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$" }, float = true })
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, float = true })
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, float = true })
-- hl.window_rule({ match = { title = "^(Firefox)$" }, float = true })
hl.window_rule({ match = { class = "^(fdm|freedownloadmanager)$" }, float = true })
hl.window_rule({ match = { class = "^(proton-authenticator)$" }, float = true })
hl.window_rule({ match = { class = "^([Ww]indscribe)$" }, float = true })

-- windowrule - ######### float popups and dialogue #######
hl.window_rule({ match = { title = "^(Authentication Required)$" }, float = true })
hl.window_rule({ match = { title = "^(Authentication Required)$" }, center = true })
-- FIXED: negative lookahead -> `negative:` prefix (see note in the POSITION section).
hl.window_rule({ match = { class = "^(codium|codium-url-handler|VSCodium)$", title = "negative:(codium|VSCodium)" }, float = true })
hl.window_rule({ match = { class = "^(com.heroicgameslauncher.hgl)$", title = "negative:Heroic Games Launcher" }, float = true })
hl.window_rule({ match = { class = "^([Ss]team)$", title = "negative:[Ss]team" }, float = true })
hl.window_rule({ match = { class = "^([Tt]hunar)$", title = "negative:[Tt]hunar" }, float = true })

hl.window_rule({ match = { title = "^(Add Folder to Workspace)$" }, float = true })
hl.window_rule({ match = { title = "^(Add Folder to Workspace)$" }, size = { "monitor_w*0.7", "monitor_h*0.6" } })
hl.window_rule({ match = { title = "^(Add Folder to Workspace)$" }, center = true })

hl.window_rule({ match = { title = "^(Save As)$" }, float = true })
hl.window_rule({ match = { title = "^(Save As)$" }, size = { "monitor_w*0.7", "monitor_h*0.6" } })
hl.window_rule({ match = { title = "^(Save As)$" }, center = true })

hl.window_rule({ match = { initial_title = "(Open Files)" }, float = true })
hl.window_rule({ match = { initial_title = "(Open Files)" }, size = { "monitor_w*0.7", "monitor_h*0.6" } })

hl.window_rule({ match = { title = "^(SDDM Background)$" }, float = true })  -- KooL's Dots YAD for setting SDDM background
hl.window_rule({ match = { title = "^(SDDM Background)$" }, center = true }) -- KooL's Dots YAD for setting SDDM background
hl.window_rule({ match = { title = "^(SDDM Background)$" }, size = { "monitor_w*0.16", "monitor_h*0.12" } }) -- KooL's Dots YAD for setting SDDM background
-- END of float popups and dialogue #######

-- OPACITY
-- MIGRATION NOTE: opacity stays a single space-separated STRING ("active inactive [fullscreen]"),
-- it is not a table.
-- hl.window_rule({ match = { tag = "browser" }, opacity = "0.9 0.7" })
-- hl.window_rule({ match = { tag = "projects" }, opacity = "0.9 0.8" })
-- hl.window_rule({ match = { tag = "im" }, opacity = "0.94 0.86" })
-- hl.window_rule({ match = { tag = "multimedia" }, opacity = "0.94 0.86" })
-- hl.window_rule({ match = { tag = "file-manager" }, opacity = "0.9 0.8" })
hl.window_rule({ match = { tag = "terminal" }, opacity = "0.8 0.7" })
hl.window_rule({ match = { tag = "settings" }, opacity = "0.8 0.7" })
-- hl.window_rule({ match = { tag = "viewer" }, opacity = "0.82 0.75" })
hl.window_rule({ match = { tag = "wallpaper" }, opacity = "0.9 0.7" })
hl.window_rule({ match = { class = "^(gedit|org.gnome.TextEditor|mousepad)$" }, opacity = "0.8 0.7" })
hl.window_rule({ match = { class = "^(deluge)$" }, opacity = "0.9 0.8" })
hl.window_rule({ match = { class = "^(seahorse)$" }, opacity = "0.9 0.8" }) -- gnome-keyring gui
-- hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, opacity = "0.95 0.75" })

-- SIZE
hl.window_rule({ match = { tag = "KooL_Cheat" }, size = { "monitor_w*0.65", "monitor_h*0.9" } })
hl.window_rule({ match = { tag = "wallpaper" }, size = { "monitor_w*0.7", "monitor_h*0.7" } })
hl.window_rule({ match = { tag = "settings" }, size = { "monitor_w*0.7", "monitor_h*0.7" } })
hl.window_rule({ match = { class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$" }, size = { "monitor_w*0.6", "monitor_h*0.7" } })
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, size = { "monitor_w*0.6", "monitor_h*0.7" } })
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, size = { "monitor_w*0.38", "monitor_h*0.38" } })
-- hl.window_rule({ match = { title = "^(Firefox)$" }, size = { "monitor_w*0.25", "monitor_h*0.25" } })

-- PINNING
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, pin = true })
-- hl.window_rule({ match = { title = "^(Firefox)$" }, pin = true })

-- windowrule - extras
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, keep_aspect_ratio = true })

-- BLUR & FULLSCREEN
hl.window_rule({ match = { tag = "games" }, no_blur = true })
hl.window_rule({ match = { tag = "games" }, fullscreen = true })

-- hl.window_rule({ match = { fullscreen = true }, border_color = "rgb(EE4B55) rgb(880808)" })
-- hl.window_rule({ match = { float = true }, border_color = "rgb(282737) rgb(1E1D2D)" })
-- hl.window_rule({ match = { pin = true }, opacity = "0.8 0.8" })


-- LAYER RULES
-- MIGRATION NOTE: `layerrule = match:namespace foo, blur on` becomes hl.layer_rule()
-- with the same match/effect split as window rules.
hl.layer_rule({ match = { namespace = "rofi" }, blur = true })
hl.layer_rule({ match = { namespace = "rofi" }, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "notifications" }, blur = true })
hl.layer_rule({ match = { namespace = "notifications" }, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "quickshell:overview" }, blur = true })
-- NOTE (pre-existing in your config, preserved as-is): ignore_alpha is set twice for
-- quickshell:overview; the later rule wins, so the effective value is 0.5.
hl.layer_rule({ match = { namespace = "quickshell:overview" }, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "quickshell:overview" }, ignore_alpha = 0.5 })

-- hl.layer_rule({ match = { namespace = "tag:notif" }, ignore_alpha = 0.5 })

-- hl.layer_rule({ match = { namespace = "class:^([Rr]ofi)$" }, ignore_alpha = 0 })
-- hl.layer_rule({ match = { namespace = "class:^([Rr]ofi)$" }, blur = true })

-- hl.layer_rule({ match = { namespace = "overview" }, ignore_alpha = 0 })
-- hl.layer_rule({ match = { namespace = "overview" }, blur = true })
