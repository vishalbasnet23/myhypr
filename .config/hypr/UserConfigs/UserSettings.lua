-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  --
-- User Settings
-- This is where you put your own settings as this will not be touched during update
-- if the upgrade.sh is used.

-- refer to Hyprland wiki for more info https://wiki.hypr.land/Configuring/Basics/Variables/

-- NOTE: some settings are in ~/.config/hypr/UserConfigs/UserDecorations.lua

-- MIGRATION NOTES:
--  * Every `section { key = value }` block becomes a nested table under hl.config().
--    hl.config() can be called many times; each call only updates what you pass in.
--  * `on`/`off` become `true`/`false`.
--  * RENAMED KEY: `tap-to-click` (hyphen) is now `tap_to_click` (underscore). The
--    hyphenated form is no longer accepted.
--  * `gestures { gesture = 3, horizontal, workspace }` is no longer a variable — it
--    moved out to its own hl.gesture() call (see bottom of this file).

-- hl.config({
--   dwindle = {
--     pseudotile           = true,
--     preserve_split       = true,
--     -- smart_split       = true,
--     special_scale_factor = 1,
--   },
-- })

hl.config({
  master = {
    new_status  = "master",
    new_on_top  = true, -- was `1`; this key is a boolean
    mfact       = 0.5,
  },

  general = {
    resize_on_border = true,
    layout           = "dwindle",
  },

  input = {
    kb_layout  = "us",
    kb_variant = "",
    kb_model   = "",
    kb_options = "",
    kb_rules   = "",

    repeat_rate  = 50,
    repeat_delay = 300,
    sensitivity  = 0.2, -- mouse sensitivity
    -- accel_profile = "", -- flat or adaptive or blank or EMPTY means libinput's default mode
    numlock_by_default = true,
    left_handed        = false,
    follow_mouse       = 1,

    float_switch_override_focus = false,

    touchpad = {
      disable_while_typing    = true,
      natural_scroll          = false,
      clickfinger_behavior    = false,
      middle_button_emulation = false,
      tap_to_click            = true, -- RENAMED: was `tap-to-click`
      drag_lock               = false,
      scroll_factor           = 0.2,
    },

    -- below for devices with touchdevice ie. touchscreen
    touchdevice = {
      enabled = true,
    },

    -- below is for tablet, see link above for proper variables
    tablet = {
      transform   = 0,
      left_handed = false, -- was `0`; this key is a boolean
    },
  },

  gestures = {
    -- MIGRATION NOTE: `workspace_swipe` and `workspace_swipe_fingers` no longer exist
    -- as gesture *variables* — swipe-to-switch is configured via hl.gesture() below.
    -- Both were already commented out in your config.
    -- workspace_swipe = true,
    -- workspace_swipe_fingers = 3,
    workspace_swipe_distance           = 500,
    workspace_swipe_invert             = true,
    workspace_swipe_min_speed_to_force = 30,
    workspace_swipe_cancel_ratio       = 0.5,
    workspace_swipe_create_new         = true,
    workspace_swipe_forever            = true,
    -- workspace_swipe_use_r = true, -- uncomment if wanted a forever create a new workspace with swipe right
  },

  misc = {
    disable_hyprland_logo     = true,
    disable_splash_rendering  = true,
    -- vfr                    = true,
    vrr                       = 2,
    mouse_move_enables_dpms   = true,
    enable_swallow            = false, -- was `off`
    swallow_regex             = "^(kitty)$",
    focus_on_activate         = false,
    initial_workspace_tracking = 0,
    middle_click_paste        = false,
    enable_anr_dialog         = true, -- Application not Responding (ANR)
    anr_missed_pings          = 15,   -- ANR Threshold default 1 is too low
  },

  -- opengl = {
  --   nvidia_anti_flicker = true,
  -- },

  binds = {
    workspace_back_and_forth = false,
    allow_workspace_cycles   = false,
    pass_mouse_when_bound    = false,
  },

  -- Could help when scaling and not pixelating
  xwayland = {
    enabled            = true,
    force_zero_scaling = true,
  },

  render = {
    direct_scanout = 0,
  },

  cursor = {
    sync_gsettings_theme     = true,
    no_hardware_cursors      = 2, -- change to 1 if want to disable
    enable_hyprcursor        = true,
    warp_on_change_workspace = 2,
    no_warps                 = true,
  },
})

-- MIGRATION NOTE: this replaces the old `gesture = 3, horizontal, workspace` line
-- that used to live inside the `gestures { }` block.
hl.gesture({
  fingers   = 3,
  direction = "horizontal",
  action    = "workspace",
})
