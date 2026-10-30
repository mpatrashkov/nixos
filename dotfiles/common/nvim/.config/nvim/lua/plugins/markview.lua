return {
  "OXY2DEV/markview.nvim",
  lazy = false, -- Markview manages its own lazy loading; load after the colorscheme.
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  opts = {
    preview = {
      filetypes = { "markdown" },
    },
  },
  keys = {
    { "<leader>mt", "<cmd>Markview toggle<cr>", desc = "Toggle Markdown preview" },
    { "<leader>ms", "<cmd>Markview splitToggle<cr>", desc = "Markdown split preview" },
  },
}
