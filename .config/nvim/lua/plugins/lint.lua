return {
  "mfussenegger/nvim-lint",
  name = "lint",
  event = { "BufReadPost", "BufWritePost" },
  config = function()
    local lint = require("lint")

    local function is_ddev_project()
      return vim.fs.find({ ".ddev" }, { upward = true, type = "directory" })[1] ~= nil
    end

    local function has_phpcs_xml()
      return vim.fs.find({ "phpcs.xml", "phpcs.xml.dist" }, { upward = true })[1] ~= nil
    end

    lint.linters_by_ft = { php = { "phpcs" } }

    if is_ddev_project() and has_phpcs_xml() then
      lint.linters.phpcs = {
        name = "phpcs",
        cmd = "ddev",
        args = function()
          return {
            "exec",
            "vendor/bin/phpcs",
            "--standard=phpcs.xml",
            "--report=emacs",
            "--no-colors",
            vim.api.nvim_buf_get_name(0),
          }
        end,
        stdin = false,
        stream = "stdout",
        exit_codes = { 0, 1 },
        parser = function(output, bufnr)
          local fixed = output:gsub("/var/www/html/", vim.fn.getcwd() .. "/")
          return require("lint.parser").from_errorformat("%f:%l:%c: %t%*[ ]-%m", {
            source = "phpcs",
            severity = {
              W = vim.diagnostic.severity.WARN,
              E = vim.diagnostic.severity.ERROR,
            },
          })(fixed, bufnr)
        end,
      }
    else
      lint.linters.phpcs = {
        name = "phpcs",
        cmd = vim.fn.expand("~/.config/composer/vendor/bin/phpcs"),
        args = function()
          return {
            "--standard=WordPress",
            "--report=emacs",
            "--no-colors",
            vim.api.nvim_buf_get_name(0),
          }
        end,
        stdin = false,
        stream = "stdout",
        exit_codes = { 0, 1 },
        parser = require("lint.parser").from_errorformat("%f:%l:%c: %t%*[ ]-%m", {
          source = "phpcs",
          severity = {
            W = vim.diagnostic.severity.WARN,
            E = vim.diagnostic.severity.ERROR,
          },
        }),
      }
    end

    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
      callback = function()
        lint.try_lint()
      end,
    })
  end,
}
