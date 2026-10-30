return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Configure nixd using Nvim 0.11+ API
      vim.lsp.config("nixd", {
        capabilities = capabilities,
      })
      vim.lsp.enable("nixd")

      vim.lsp.config("svelte", {
        capabilities = capabilities,
      })
      vim.lsp.enable("svelte")

      -- clangd for C/C++ (only enable when clangd is on PATH, e.g. inside devenv)
      vim.lsp.config("clangd", {
        capabilities = capabilities,
        cmd = { "clangd", "--query-driver=**/xtensa-esp32-elf-*" },
      })
      if vim.fn.executable("clangd") == 1 then
        vim.lsp.enable("clangd")
      end

      -- Keymaps for LSP actions (only when an LSP is attached to the buffer)
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          local function map(keys, action, description)
            vim.keymap.set("n", keys, action, { buffer = ev.buf, desc = description })
          end

          map("gd", vim.lsp.buf.definition, "LSP: go to definition")
          map("K", vim.lsp.buf.hover, "LSP: hover documentation")
          map("<leader>rn", vim.lsp.buf.rename, "LSP: rename symbol")
          map("<leader>ca", vim.lsp.buf.code_action, "LSP: code action")
          map("gr", vim.lsp.buf.references, "LSP: find references")
        end,
      })
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
    },
    config = function()
      local cmp = require("cmp")

      cmp.setup({
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
          ["<Tab>"] = cmp.mapping.confirm({ select = true }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },
}
