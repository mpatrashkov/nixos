return {
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local telescope = require('telescope')
      local builtin = require('telescope.builtin')

      telescope.setup({
        defaults = {
          file_ignore_patterns = { "%.git/" },
          preview = {
            treesitter = false,
          },
        },
      })

      vim.keymap.set('n', '<leader>ff', function() builtin.find_files({ hidden = true }) end, { desc = 'Telescope find files (hidden)' })
      vim.keymap.set('n', '<leader>fg', function() builtin.live_grep({ additional_args = function() return { "--hidden" } end }) end, { desc = 'Telescope live grep (hidden)' })
      vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
      vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
    end,
  }
}
