return {
  "saghen/blink.cmp",
  ---@class PluginLspOpts
  opts = {
    signature = { enabled = true },
    keymap = {
      preset = "enter",
      ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
      ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
    },
  },
}
