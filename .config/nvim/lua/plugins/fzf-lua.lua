return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local fzf = require("fzf-lua")
    local actions = require("fzf-lua.actions")
    fzf.setup({
      grep = {
        rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=512",
        actions = {
          ["default"] = actions.file_edit,
        },
      },
      files = {
        actions = {
          ["default"] = actions.file_edit,
        },
      },
    })

    -- Override the default grep action to properly handle file opening
    fzf.register_ui_select()
  end,
  keys = {
    { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find files" },
    { "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Live grep" },
  },
}
