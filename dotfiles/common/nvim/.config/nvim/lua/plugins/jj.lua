return {
  "julienvincent/hunk.nvim",
  dependencies = { "MunifTanjim/nui.nvim" },
  cmd = { "HunkDiffView" },
  opts = {
    ui = {
      tree = { mode = "flat", width = 40, use_float = false },
      layout = "vertical",
    },
  },
}
