-- Entry point. Keep this file thin; real config lives under lua/.

-- Leader keys must be set before lazy.nvim loads so plugin mappings see them.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Bootstrap lazy.nvim (https://lazy.folke.io/installation)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Load plugin specs from lua/plugins/*.lua
require("lazy").setup({
  spec = { { import = "plugins" } },
  change_detection = { notify = false },
})
