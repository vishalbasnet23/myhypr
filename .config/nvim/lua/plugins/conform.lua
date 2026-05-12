return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      javascript = { "biome", "prettier", stop_after_first = true },
      typescript = { "biome", "prettier", stop_after_first = true },
      javascriptreact = { "biome", "prettier", stop_after_first = true },
      typescriptreact = { "biome", "prettier", stop_after_first = true },
      astro = { "biome", "prettier", stop_after_first = true },
      json = { "biome", "prettier", stop_after_first = true },
      jsonc = { "biome", "prettier", stop_after_first = true },
      php = { "phpcbf" },
    },
    formatters = {
      biome = {
        condition = function(_, ctx)
          return vim.fs.find({ "biome.json" }, { path = ctx.filename, upward = true })[1]
        end,
      },
      phpcbf = {
        command = vim.fn.expand("~/.config/composer/vendor/bin/phpcbf"),
        args = { "--standard=WordPress", "$FILENAME" },
        stdin = false,
        exit_codes = { 0, 1 },
      },
    },
  },
}
