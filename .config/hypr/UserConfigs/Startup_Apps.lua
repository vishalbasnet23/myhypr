-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  --
-- Commands and Apps to be executed at launch

-- MIGRATION NOTE: `exec-once` has no direct keyword any more. Autostart is now
-- done by subscribing to the "hyprland.start" event and calling hl.exec_cmd().
-- hl.exec_cmd() already spawns asynchronously, so trailing `&` / `disown` are
-- unnecessary (the stray `&` on the old kdeconnectd line has been dropped).

local HOME        = os.getenv("HOME")
local scriptsDir  = HOME .. "/.config/hypr/scripts"
local UserScripts = HOME .. "/.config/hypr/UserScripts"

local wallDIR       = HOME .. "/Pictures/wallpapers"
local lock          = scriptsDir .. "/LockScreen.sh"
local SwwwRandom    = UserScripts .. "/WallpaperAutoChange.sh"
local livewallpaper = ""

-- NOTE: `lock`, `wallDIR`, `SwwwRandom` and `livewallpaper` are referenced only by the
-- commented-out lines below (and by shell scripts that grep the .conf files). Kept so
-- this stays a faithful translation.

hl.on("hyprland.start", function()
  -- wallpaper stuff
  -- hl.exec_cmd("/usr/bin/wpaperd -d")
  --
  hl.exec_cmd("awww-daemon")

  -- hl.exec_cmd("mpvpaper '*' -o \"load-scripts=no no-audio --loop\" " .. livewallpaper)

  -- wallpaper random
  -- hl.exec_cmd(SwwwRandom .. " " .. wallDIR) -- random wallpaper switcher every 30 minutes

  -- Startup
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
  hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

  -- Polkit (Polkit Gnome / KDE)
  hl.exec_cmd(scriptsDir .. "/Polkit.sh")

  -- starup apps
  hl.exec_cmd("nm-applet --indicator")
  hl.exec_cmd("swaync")
  -- hl.exec_cmd("ags")
  -- hl.exec_cmd("blueman-applet")
  -- hl.exec_cmd("rog-control-center")
  hl.exec_cmd("waybar")
  hl.exec_cmd("qs") -- quickshell AGS Desktop Overview alternative
  hl.exec_cmd("/usr/bin/kdeconnectd")
  hl.exec_cmd("/usr/bin/kdeconnect-indicator")

  -- clipboard manager
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")

  -- Rainbow borders
  -- hl.exec_cmd(UserScripts .. "/RainbowBorders.sh")

  -- Starting hypridle to start hyprlock
  hl.exec_cmd("hypridle")

  -- Here are list of features available but disabled by default
  -- hl.exec_cmd("swww-daemon --format xrgb && swww img " .. HOME .. "/Pictures/wallpapers/mecha-nostalgia.png") -- persistent wallpaper

  -- gnome polkit for nixos
  -- hl.exec_cmd(scriptsDir .. "/Polkit-NixOS.sh")

  -- xdg-desktop-portal-hyprland (should be auto starting. However, you can force to start)
  -- hl.exec_cmd(scriptsDir .. "/PortalHyprland.sh")
end)

-- MIGRATION NOTE: the two `exec =` (not `exec-once`) lines below ran at startup
-- AND again on every config reload. To preserve that, the same function is
-- subscribed to both "hyprland.start" and "config.reloaded".
local function applyGtkTheme()
  hl.exec_cmd('gsettings set org.gnome.desktop.interface gtk-theme "Andromeda-dark"') -- for GTK3 apps
  hl.exec_cmd('gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"') -- for GTK4 apps
end

hl.on("hyprland.start", applyGtkTheme)
hl.on("config.reloaded", applyGtkTheme)

hl.env("QT_QPA_PLATFORMTHEME", "qt6ct") -- for Qt apps
