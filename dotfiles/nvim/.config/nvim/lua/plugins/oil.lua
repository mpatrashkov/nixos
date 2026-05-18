return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    -- The default configuration is generally excellent.
    -- We'll keep it empty for now, which uses the defaults.
    -- You can customize things like sorting, hidden files, etc. here later.
  },
  keys = {
    { "-", "<cmd>Oil<cr>", desc = "Open parent directory with Oil" },
  },
}
