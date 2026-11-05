return {
  "sindrets/diffview.nvim",
  event = "VeryLazy",
  opts = function()
    if vim.env.JJ_REVIEW_MODE ~= "live" and vim.env.JJ_REVIEW_MODE ~= "historical" then
      return {}
    end

    return {
      view = { default = { layout = "diff2_horizontal" } },
      keymaps = {
        file_panel = {
          { "n", "-", false },
          { "n", "s", false },
          { "n", "S", false },
          { "n", "U", false },
          { "n", "X", false },
        },
        file_history_panel = { { "n", "X", false } },
      },
      hooks = {
        view_opened = function(view)
          require("review_annotations.diffview").opened(view)
        end,
        view_closed = function(view)
          require("review_annotations.diffview").closed(view)
        end,
        view_enter = function(view)
          require("review_annotations.diffview").visibility(view, true)
        end,
        view_leave = function(view)
          require("review_annotations.diffview").visibility(view, false)
        end,
        diff_buf_win_enter = function(buf, win, context)
          require("review_annotations.diffview").mount(buf, win, context)
        end,
      },
    }
  end,
  keys = {
    { "<leader>gdo", "<cmd>DiffviewOpen<CR>", desc = "Diffview Open" },
    { "<leader>gdc", "<cmd>DiffviewClose<CR>", desc = "Diffview Close" },
    { "<leader>gdh", "<cmd>DiffviewFileHistory %<CR>", desc = "Diffview File History" },
  },
}
