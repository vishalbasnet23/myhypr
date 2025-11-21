return {
  {
    "ray-x/aurora",
    init = function()
      vim.g.aurora_italic = true
      vim.g.aurora_transparent = 1
      vim.g.aurora_bold = 1
      vim.api.nvim_set_hl(0, "LineNr", { fg = "#9b59b6" }) -- Vibrant Purple
    end,
    config = function()
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          vim.api.nvim_set_hl(0, "LineNr", {}) -- Reset any existing highlight
          vim.api.nvim_set_hl(0, "LineNr", { fg = "#9b59b6" }) -- Vibrant Purple
          vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#e933e3", bold = true })
        end,
      })
    end,
  },
  {
    "uloco/bluloco.nvim",
    lazy = false,
    priority = 1000,
    dependencies = { "rktjmp/lush.nvim" },
    config = function()
      require("bluloco").setup({
        transparent = true,
        italics = true,
        guicursor = true,
      })
    end,
  },
  {
    "zootedb0t/citruszest.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("citruszest").setup({
        option = {
          transparent = true, -- Enable/Disable transparency
          italics = {
            comments = true, -- Boolean: Italicizes comments
            keywords = true, -- Boolean: Italicizes keywords
            functions = true, -- Boolean: Italicizes functions
            strings = true, -- Boolean: Italicizes strings
            variables = true, -- Boolean: Italicizes variables
          },
          overrides = {},
        },
        style = {
          Constant = { fg = "#FFFFFF", bold = false },
        },
      })
    end,
  },
  {
    "DonJulve/NeoCyberVim.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("NeoCyberVim").setup({
        transparent = true, -- Boolean: Sets the background to transparent
        italics = {
          comments = true, -- Boolean: Italicizes comments
          keywords = false, -- Boolean: Italicizes keywords
          functions = true, -- Boolean: Italicizes functions
          strings = false, -- Boolean: Italicizes strings
          variables = false, -- Boolean: Italicizes variables
        },
        overrides = {},
      })
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "NeoCyberVim",
    },
  },
}
