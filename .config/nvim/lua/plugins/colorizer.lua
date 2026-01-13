return {
  {
    "NvChad/nvim-colorizer.lua",
    config = function()
      require("colorizer").setup({
        user_default_options = {
          RGB = true,
          RRGGBB = true,
          names = false,
          RRGGBBAA = true,
          OKLCH = true, -- Enable OKLCH support
          rgb_fn = true,
          hsl_fn = true,
          css = true,
          css_fn = true,
          tailwind = true, -- Enable Tailwind CSS support
          mode = "background", -- 'foreground' | 'background' | 'virtualtext'
        },
        filetypes = {
          "*", -- Highlight all files
          css = { css = true },
          html = { tailwind = true },
        },
      })
    end,
  },
}
