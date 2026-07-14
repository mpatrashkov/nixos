return {
  "sindrets/diffview.nvim",
  event = "VeryLazy",
  keys = {
    { "<leader>gdo", "<cmd>DiffviewOpen<CR>", desc = "Diffview Open" },
    { "<leader>gdc", "<cmd>DiffviewClose<CR>", desc = "Diffview Close" },
    { "<leader>gdh", "<cmd>DiffviewFileHistory %<CR>", desc = "Diffview File History" },
  },
}
