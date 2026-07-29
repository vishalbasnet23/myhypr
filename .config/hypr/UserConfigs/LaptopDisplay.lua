-- NOTE, THIS FILE IS BEING USED by disabling Laptop display monitor behaviour when closing lid.
-- See notes on Laptops.lua

-- MIGRATION NOTE: `monitor = eDP-1, preferred, auto, 1` becomes hl.monitor() with
-- named fields. To disable an output, use `disabled = true` instead of the old
-- `, disable` positional keyword.

-- hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1 })
