return {
  "folke/snacks.nvim",
  opts = {
    explorer = {
      -- show gitignored files
      hidden = true,
      ignored = true,
    },
    picker = {
      sources = {
        explorer = {
          hidden = true,
          ignored = true,
        },
      },
    },
  },
}
