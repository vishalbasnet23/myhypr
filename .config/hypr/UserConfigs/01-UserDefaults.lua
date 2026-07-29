-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  --

-- This is a file where you put your own default apps, default search Engine etc

-- MIGRATION NOTE: in hyprlang these were `$variables`, which were global across
-- every sourced file. Lua has no equivalent global config namespace, so this
-- file RETURNS a table instead and consumers pull what they need:
--     local defaults = require("UserConfigs.01-UserDefaults")
--     defaults.term, defaults.files, ...

-- Set your default editor here uncomment and reboot to take effect.
-- NOTE, this will be automatically uncommented if you select neovim or vim to your default editor
-- hl.env("EDITOR", "vim") -- default editor

return {
  -- Define preferred text editor for the KooL Quick Settings Menu (SUPER SHIFT E)
  -- script will take the default EDITOR and nano as fallback
  -- MIGRATION NOTE: hyprlang stored the *literal* string "${EDITOR:-nvim}" and left
  -- the expansion to whichever shell script consumed it. Lua resolves it here.
  edit = os.getenv("EDITOR") or "nvim",

  -- These two are for UserKeybinds.lua & Waybar Modules
  term  = "kitty",    -- Terminal
  files = "nautilus", -- File Manager

  -- Default Search Engine for ROFI Search (SUPER S)
  Search_Engine = "https://www.google.com/search?q={}",
}
