return {
  "julienvincent/hunk.nvim",
  dependencies = { "MunifTanjim/nui.nvim" },
  cmd = { "HunkDiffView" },
  opts = {
    ui = {
      tree = { mode = "flat", width = 40, use_float = false },
      layout = "vertical",
    },
    hooks = {
      on_tree_mount = function(context)
        require("review_annotations.jj").tree_mount(context)
      end,
      on_diff_mount = function(context)
        require("review_annotations.jj").diff_mount(context)
      end,
    },
  },
}
