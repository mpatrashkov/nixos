return {
  "ellisonleao/gruvbox.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    vim.opt.termguicolors = true
    vim.opt.background = "dark"

    -- Match VS Code's Gruvbox DrakenLords Dark Draken variant, not stock Gruvbox.
    -- TextMate scopes and Treesitter captures differ, so token mappings are approximate.
    require("gruvbox").setup({
      bold = false,
      italic = {
        strings = false,
        comments = true,
        operators = false,
        folds = false,
      },
      palette_overrides = {
        dark0 = "#031417",
      },
      overrides = {
        NormalFloat = { fg = "#ebdbb2", bg = "#031417" },
        FloatBorder = { fg = "#fbf1c7", bg = "#031417" },
        SignColumn = { bg = "#031417" },
        LineNr = { fg = "#ebdbb2", bg = "#031417" },
        CursorLineNr = { fg = "#83a598", bg = "#031417" },
        CursorLine = { bg = "#282828" },
        Cursor = { fg = "#98971a", bg = "#b8bb26" },
        -- VS Code's translucent selection (#ebdbb23f), blended over #031417.
        Visual = { bg = "#3c4540", reverse = false },
        Search = { fg = "#031417", bg = "#7c6f64" },
        IncSearch = { fg = "#031417", bg = "#fbf1c7" },
        Pmenu = { fg = "#ebdbb2", bg = "#031417" },
        PmenuSel = { fg = "#ebdbb2", bg = "#282828" },
        StatusLine = { fg = "#ebdbb2", bg = "#031417", reverse = false },
        StatusLineNC = { fg = "#928374", bg = "#031417", reverse = false },
        Function = { fg = "#fabd2f" },
        Operator = { fg = "#8ec07c" },
        ["@variable"] = { fg = "#83a598" },
        ["@variable.parameter"] = { fg = "#83a598" },
        ["@variable.member"] = { fg = "#83a598" },
        ["@function.call"] = { fg = "#8ec07c" },
        ["@function.builtin"] = { fg = "#fe8019" },
        ["@function.method"] = { fg = "#689d6a" },
        ["@function.method.call"] = { fg = "#689d6a" },
        ["@function.typescript"] = { fg = "#83a598" },
      },
    })

    vim.cmd.colorscheme("gruvbox")
  end,
}
