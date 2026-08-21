# Hyprland `.conf` → Lua migration notes

Migrated against **Hyprland 0.56.1**. Syntax verified against the version-matched
API stubs at `/usr/share/hypr/stubs/hl.meta.lua`, the shipped example
`/usr/share/hypr/hyprland.lua`, and the current wiki (not from memory).

## Activate / roll back

Hyprland ≥ 0.55 loads `hyprland.lua` **instead of** `hyprland.conf` when it exists.
The choice is made once, at startup. The entry point is staged under a name that
does *not* trigger the switch, so nothing has changed yet:

```sh
# activate
mv ~/.config/hypr/hyprland.lua.new ~/.config/hypr/hyprland.lua
# then log out and back in (the switch only happens at startup)

# roll back
rm ~/.config/hypr/hyprland.lua      # hyprland.conf takes over again
```

Every original `.conf` was left untouched at migration time, so rollback was that
single `rm`.

> **Update 2026-08-21 — the `.conf` tree has been deleted from the working tree.**
> All 32 migrated `.conf` files (`hyprland.conf`, `configs/Keybinds.conf`, the
> `UserConfigs/*.conf` set, `animations/*.conf`, `Monitor_Profiles/default.conf`)
> plus the never-sourced `application-style.conf` and `wallust/wallust-hyprland.conf`
> are gone. Nothing loaded them — Hyprland reads `hyprland.lua`, and the pickers were
> rewritten to copy `*.lua` presets only.
>
> **Rollback is now git, which is what it always really was:** the notes below already
> said the patched scripts must be reverted alongside the config, and that is a
> checkout either way.
>
> ```sh
> git checkout fdc1e5b^ -- .config/hypr   # restore the whole pre-migration tree
> rm ~/.config/hypr/hyprland.lua          # hand control back to hyprland.conf
> ```
>
> `hyprlock.conf` and `hypridle.conf` are untouched by all of this — they belong to
> hyprlock/hypridle, which never moved to Lua.

## Files

| Old | New |
|---|---|
| `hyprland.conf` | `hyprland.lua.new` (staged) |
| `configs/Keybinds.conf` | `configs/Keybinds.lua` |
| `UserConfigs/01-UserDefaults.conf` | `UserConfigs/01-UserDefaults.lua` |
| `UserConfigs/ENVariables.conf` | `UserConfigs/ENVariables.lua` |
| `UserConfigs/Startup_Apps.conf` | `UserConfigs/Startup_Apps.lua` |
| `UserConfigs/Laptops.conf` | `UserConfigs/Laptops.lua` |
| `UserConfigs/LaptopDisplay.conf` | `UserConfigs/LaptopDisplay.lua` |
| `UserConfigs/WindowRules.conf` | `UserConfigs/WindowRules.lua` |
| `UserConfigs/UserDecorations.conf` | `UserConfigs/UserDecorations.lua` |
| `UserConfigs/UserAnimations.conf` | `UserConfigs/UserAnimations.lua` |
| `UserConfigs/UserKeybinds.conf` | `UserConfigs/UserKeybinds.lua` |
| `UserConfigs/UserSettings.conf` | `UserConfigs/UserSettings.lua` |
| `monitors.conf` / `workspaces.conf` | `monitors.lua` / `workspaces.lua` (nwg-displays already wrote these) |

`source =` became `require()`. Hyprland puts `<config-dir>/?.lua` on `package.path`,
so `require("UserConfigs.UserSettings")` resolves to `UserConfigs/UserSettings.lua`.
Load order is preserved exactly — it matters, because window rules apply top-to-bottom
and later `hl.config()` calls override earlier ones.

`UserConfigs/WindowRules-old.conf`, `Monitor_Profiles/`, `animations/*.conf`,
`application-style.conf` and `wallust/wallust-hyprland.conf` were **not** migrated —
none are in the `hyprland.conf` source chain. `hyprlock.conf` / `hypridle.conf` belong
to hyprlock/hypridle, which still use hyprlang.

## What was verified

The full tree was loaded in a nested Hyprland instance and the live instance queried:

- **152 binds** registered, **126 window rules**, **7 layer rules**, **10 workspace
  rules**, **2 monitors**, **14 bezier curves**, **11 animations**, **20 env vars**,
  **16 autostart commands**, **1 device**, **1 gesture** — each matching the original
  `.conf` counts exactly (binds 153 → 152; see the invalid keysym below).
- Zero load errors, zero unknown config keys.
- Spot-checked applied values: `border_size=1`, `rounding=4`, `blur:passes=2`,
  `tap_to_click=true`, `vrr=2`, `no_hardware_cursors=2`, `mfact=0.5`.

Three rewrites that could not be proven by loading alone were dispatched live in the
nested instance and **all pass**:

- `hl.dsp.window.set_prop({ prop = "opaque", value = "toggle" })` → `ok`, so
  `SUPER + CTRL + O` behaves as before.
- The zoom rewrite compounds correctly: repeated `SUPER + ALT + scroll up` gives
  1 → 2 → 4 → 8, and scroll down returns 4. `hl.get_config()` returns a usable number.
- `hl.dsp.layout("...")` passes the message through verbatim — `togglesplit` succeeded
  under dwindle, and the five master messages returned
  `Unknown dwindle layoutmsg: ...`, i.e. they reach the layout unchanged and, exactly as
  with the old `layoutmsg`, only apply while the master layout is active.

## Two pre-existing bugs the migration exposed

Both were already broken under hyprlang, just silently.

1. **`XF86AudioPlayPause` is not a real keysym.** No such symbol exists in xkbcommon.
   Under hyprlang it failed quietly; under Lua `hl.bind` raises. Commented out in
   `configs/Keybinds.lua`. Nothing lost — `XF86AudioPlay` and `XF86AudioPause` are both
   still bound and both already ran `MediaCtrl.sh --pause`.

2. **Five window rules used negative lookahead** (`^((?!.*[Tt]hunar).)*$`). Hyprland
   matches with Google RE2, which has no lookahead — it logged
   `invalid perl operator: (?!` and those title props never matched. Rewritten using the
   supported `negative:` prefix, e.g. `title = "negative:[Tt]hunar"`. Affects the
   Thunar (×2), VSCodium, Heroic and Steam dialog rules. **These now actually work**,
   so you may see those dialogs float/center for the first time.

## Needs your eyes after switching

- **`%` sizes and positions.** hyprlang took `size 25% 55%` / `move 61% 7%`. The Lua
  form takes numbers or expression strings and `%` is undocumented, so each was written
  as `{"monitor_w*0.25", "monitor_h*0.55"}`. Same reference frame, but worth a visual
  check on: **Picture-in-Picture** (move + size), **Save As** / **Add Folder to
  Workspace** (70%×60%), **SDDM Background** (16%×12%), **KooL Cheat Sheet** (65%×90%).
- **Dialogs that will now float/center for the first time.** The five `negative:` rules
  above were dead under hyprlang. Expect Thunar sub-dialogs, VSCodium dialogs, the
  Heroic and Steam non-main windows to start floating (and Thunar dialogs to centre).
  This is the fix working, not a regression — but it is the most visible change.
- **`CTRL + ALT + Delete`** now calls `hl.dsp.exit()` directly. If you ever move to
  **uwsm**, the wiki warns against `exit` — use `hl.dsp.exec_cmd("uwsm stop")` instead.

## Deprecated with no replacement

- **`SUPER + ALT + SPACE`** (All Float Mode) used `hyprctl dispatch workspaceopt allfloat`.
  `workspaceopt` is absent from the 0.55+ dispatcher list and has no documented
  successor. The bind is preserved verbatim so nothing is silently dropped, but it will
  no-op until you pick a replacement.

## Renamed

- `input:touchpad:tap-to-click` → **`tap_to_click`** (hyphen no longer accepted).
- `master:new_on_top` / `input:tablet:left_handed` are booleans now, not `1`/`0`.
- `misc:enable_swallow = off` → `false`.
- Gestures: `gesture = 3, horizontal, workspace` moved out of the `gestures {}` block
  into its own `hl.gesture({ fingers = 3, ... })` call.

## Helper scripts — migrated

The load-bearing fact: **`hyprctl keyword` is dead under a Lua config.** It refuses
outright with `keyword can't work with non-legacy parsers. Use eval.` Reads via
`hyprctl getoption` still work, and `hyprctl eval '<lua>'` is the replacement for writes.

| Script | Bound to | What changed |
|---|---|---|
| `scripts/TouchPad.sh` | `XF86TouchpadToggle` | Set a hyprlang `$TOUCHPAD_ENABLED` variable — a concept that no longer exists. Now calls `hl.device({ name, enabled })` via `eval`, with the device **auto-detected** from `hyprctl devices` (falls back to the name in `Laptops.lua`) |
| `scripts/ChangeBlur.sh` | `SUPER + SHIFT + O` | `keyword decoration:blur:*` → one `eval` with `hl.config()` |
| `scripts/ChangeLayout.sh` | `SUPER + ALT + L` | `keyword unbind/bind` → `hl.unbind()` / `hl.bind()` with the renamed dispatchers |
| `scripts/GameMode.sh` | via Quick Settings | `keyword --batch` → one `hl.config()`; the global windowrule → a *named* `hl.window_rule()` so it can be switched off again |
| `scripts/Animations.sh` | `SUPER + SHIFT + A` | Now lists and copies `animations/*.lua` → `UserAnimations.lua` |
| `scripts/MonitorProfiles.sh` | via Quick Settings | Now lists and copies `Monitor_Profiles/*.lua` → `monitors.lua` |
| `scripts/KeyBinds.sh` | `SUPER + ALT + K` | Greps `hl.bind(` out of the `.lua` files and tidies them for display |
| `scripts/Kool_Quick_Settings.sh` | `SUPER + SHIFT + E` | Edit targets repointed to `.lua`; gained a "view/edit Main Config" entry |
| `scripts/RofiSearch.sh`, `WaybarScripts.sh`, `Kool_Quick_Settings.sh` | various | The `sed \| eval` hack against `01-UserDefaults.conf` → shared helper `scripts/UserDefaults.sh` |
| `scripts/SwitchKeyboardLayout.sh`, `Tak0-Per-Window-Switch.sh` | (unbound) | Grepped `kb_layout` out of `UserSettings.conf` → `hyprctl getoption input:kb_layout` (format-agnostic, reads the *running* value) |
| `UserScripts/WallpaperSelect.sh` | `SUPER + SHIFT + W` | `modify_startup_config()` retargeted to `Startup_Apps.lua` with `--` comments |
| `UserScripts/SyncDotfiles.sh` | (unbound) | `kb_options` sed retargeted to `UserSettings.lua` and quoted-string syntax |

New files: `scripts/UserDefaults.sh` (sourceable; exports `$term $files $edit
$Search_Engine`) and `scripts/user-defaults-emit.lua` (reads the Lua table, emits
shell-quoted assignments). `scripts/KeyHints.sh` and `scripts/DarkLight.sh` were checked
and needed **no** change — the first only prints a directory name, the second assigns a
path variable it never uses.

### Why `KeyBinds.sh` still parses files

`hyprctl binds -j` looks like the better source, but under a Lua config every bind
reports its dispatcher as the opaque `__lua` with an integer arg, and `description` is
empty on all 152. The menu would have become a list of `__lua 7`. Parsing the config
keeps the human-readable trailing comments.

### Bugs found and fixed while migrating these

- **`GameMode.sh` could never enable.** It compared `hyprctl getoption animations:enabled`
  against `1`, but Hyprland reports `bool: true`. Now read as JSON.
- **`GameMode.sh` never restored.** The trailing `hyprctl reload` was unreachable (both
  branches `exit`), so disabling game mode only restarted the wallpaper daemon. `reload`
  re-reads and re-applies the Lua config (verified), so it now runs in the disable branch.
- **`ChangeLayout.sh` ate your vim keys.** `unbind SUPER+J` is case-insensitive, so it
  also removed the `SUPER+j`/`SUPER+k` movefocus binds until the next reload. They are
  now re-added explicitly.
- **`WallpaperSelect.sh`'s image/video toggle half-worked.** Its `awww-daemon` patterns
  required `--format xrgb`, which the actual line never had. The new patterns match.

### Animation presets: 4 values clamped

All 17 presets were converted and load-tested individually. The Lua API enforces bounds
hyprlang did not, and four values exceeded them:

- `borderangle` speed `180` → **100** (the cap) in `00-default`, `01-default - v2` and
  `Mahaveer - me-2`. Those rainbow-border rotations will run ~1.8× faster than before;
  lower `speed` further if you want the old pace.
- Bezier `nice` points `{0, 6.9}, {0.5, -4.20}` → clamped to the `[-1, 2]` bound. That
  curve is not referenced by any animation in its preset, so no visible effect.

Out-of-range directives are *skipped* rather than fatal, so clamping keeps them active.

### Reload semantics (tested, because several scripts depend on them)

- **Auto-reload still works, including on `require`d sub-files.** Overwriting
  `UserConfigs/UserAnimations.lua` took effect within ~2s with no explicit reload, so the
  animation and monitor-profile pickers apply immediately, same as before.
- **`hyprctl reload` does not re-fire `hyprland.start`.** The entry point re-executes, but
  the autostart handlers fire only once per session — so `GameMode.sh` calling `reload`
  will *not* spawn a second waybar/swaync/kdeconnect.
- **`require` caching does not stale the config.** A reload picks up new sub-file contents.

### Rollback caveat

The fixed scripts target the Lua config. If you `rm hyprland.lua` to roll back, also
`git checkout` the scripts — they are all in this repo, so that is one command.
