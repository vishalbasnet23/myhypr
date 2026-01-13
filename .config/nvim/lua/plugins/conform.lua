return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      javascript = { "biome" },
      typescript = { "biome" },
      javascriptreact = { "biome" },
      typescriptreact = { "biome" },
      astro = { "biome" },
      json = { "biome" },
      jsonc = { "biome" },
    },
    formatters = {
      biome = {
        condition = function(_, ctx)
          return vim.fs.find({ "biome.json" }, { path = ctx.filename, upward = true })[1]
        end,
      },
    },
  },
}
