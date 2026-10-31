return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main", -- The legacy master branch only supports Neovim through 0.11.
  lazy = false,
  build = ":TSUpdate",
  config = function()
    local treesitter = require("nvim-treesitter")
    local parsers = {
      "c",
      "lua",
      "nix",
      "vim",
      "vimdoc",
      "query",
      "svelte",
      "javascript",
      "typescript",
      "html",
      "css",
      "markdown",
      "markdown_inline",
    }
    treesitter.setup({})
    treesitter.install(parsers)

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("TreesitterFeatures", { clear = true }),
      callback = function(event)
        local language = vim.treesitter.language.get_lang(vim.bo[event.buf].filetype)
        if not language or not vim.treesitter.language.add(language) then
          return
        end

        vim.treesitter.start(event.buf, language)
        vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
