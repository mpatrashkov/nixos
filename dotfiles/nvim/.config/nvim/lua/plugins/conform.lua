return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>F",
      function() require("conform").format({ async = true, lsp_fallback = true }) end,
      mode = { "n", "v" },
      desc = "Format buffer/selection",
    },
  },
  opts = {
    formatters_by_ft = {
      svelte     = { "prettier" },
      javascript = { "prettier" },
      typescript = { "prettier" },
      html       = { "prettier" },
      css        = { "prettier" },
      json       = { "prettier" },
      markdown   = { "prettier" },
      yaml       = { "prettier" },
    },
    format_on_save = {
      timeout_ms = 2000,
      lsp_fallback = true,
    },
  },
}
