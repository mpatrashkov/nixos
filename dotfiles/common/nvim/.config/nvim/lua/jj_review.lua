local M = {}

-- A dedicated editor session: JJ owns these directories until Neovim exits.
-- Paths arrive as environment values, never as generated Lua or Ex commands.
function M.start()
  local left = vim.env.JJ_REVIEW_LEFT
  local right = vim.env.JJ_REVIEW_RIGHT
  local ok, result = pcall(function()
    assert(left and right, "Launch this viewer using jj review or jjui Ctrl-o")
    return require("hunk").view(left, right)
  end)

  if not ok or result ~= true then
    vim.api.nvim_err_writeln("JJ review failed: " .. tostring(result))
    vim.cmd("cquit 1")
  end
end

return M
