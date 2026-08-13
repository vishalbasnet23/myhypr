-- Decoration Settings — Vibrant Theme (no wallust)

-- MIGRATION NOTE: hyprlang `$colour = rgba(...)` variables become plain Lua locals.
-- Gradients (`$a $b 45deg`) become a table: { colors = { a, b }, angle = 45 }.
-- A single colour stays a plain string.

-- Vibrant Palette
local blue = "rgba(2979ffee)"
local lavender = "rgba(8e5cffee)"
local sapphire = "rgba(00bcd4ee)"
local sky = "rgba(00e5ffee)"
local teal = "rgba(00d4a3ee)"
local green = "rgba(00e676ee)"
local yellow = "rgba(ffd600ee)"
local peach = "rgba(ff9100ee)"
local pink = "rgba(ff4081ee)"
local mauve = "rgba(d500f9ee)"
local flamingo = "rgba(ff6e6eee)"
local red = "rgba(ff3d00ee)"
local surface0 = "rgba(2c2f4855)"
local surface1 = "rgba(3a3e5c55)"
local overlay0 = "rgba(62689a88)"

-- Only teal, sky, blue, surface0 and surface1 are used below; the rest of the palette
-- is kept for future use, exactly as in the original.

hl.config({
	general = {
		border_size = 1,
		gaps_in = 3,
		gaps_out = 4,

		-- MIGRATION NOTE: `col.active_border = $teal $teal 45deg` -> nested `col` table
		-- with a gradient value. `45deg` becomes `angle = 45`.
		col = {
			active_border = { colors = { flamingo, flamingo }, angle = 45 },
			inactive_border = { colors = { yellow, teal }, angle = 45 },
		},
	},

	decoration = {
		rounding = 4,
		active_opacity = 1.0,
		inactive_opacity = 0.5,
		fullscreen_opacity = 1.0,
		dim_inactive = true,
		dim_strength = 0.1,
		dim_special = 0.8,

		shadow = {
			enabled = true,
			range = 5,
			render_power = 4,
			color = flamingo,
			color_inactive = surface0,
		},

		blur = {
			enabled = true,
			size = 5,
			passes = 2,
			ignore_opacity = true,
			new_optimizations = true,
			special = true,
			popups = false,
			xray = true,
		},
	},

	group = {
		col = {
			border_active = { colors = { flamingo, pink }, angle = 45 },
			border_inactive = surface1,
		},

		groupbar = {
			col = {
				active = pink,
				inactive = surface0,
			},
		},
	},
})
