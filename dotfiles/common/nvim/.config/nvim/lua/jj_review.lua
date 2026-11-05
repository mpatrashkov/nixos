local M = {}

-- A dedicated editor session: JJ owns these directories until Neovim exits.
-- Paths arrive as environment values, never as generated Lua or Ex commands.
function M.start()
  local left = vim.env.JJ_REVIEW_LEFT
  local right = vim.env.JJ_REVIEW_RIGHT
  local ok, result = pcall(function()
    assert(left and right, "Launch this viewer using jj review or jjui Ctrl-o")
    local mode = vim.env.JJ_REVIEW_MODE
    if mode == "legacy" then
      require("review_annotations.jj").start(left, right)
      return require("hunk").view(left, right)
    end

    assert(mode == "live" or mode == "historical", "Launch using jj review (or jj review-legacy)")
    local root = assert(vim.env.JJ_REVIEW_ROOT, "Missing workspace root")
    local parent = assert(vim.env.JJ_REVIEW_PARENT, "Missing parent commit")
    local selected = assert(vim.env.JJ_REVIEW_SELECTED, "Missing selected commit")
    assert(parent:match("^[0-9a-f]+$") and #parent == 40, "Invalid parent commit")
    assert(selected:match("^[0-9a-f]+$") and #selected == 40, "Invalid selected commit")
    vim.api.nvim_set_current_dir(root)
    require("review_annotations.diffview").start(root, left, right)
    require("lazy").load({ plugins = { "diffview.nvim" } })

    local revision = parent
    if mode == "historical" then
      revision = parent .. ".." .. selected
    end
    require("diffview").open({ "-C" .. root, revision, "--untracked-files=all" })
    vim.notify(mode == "live"
      and "JJ review: live working files; edits invalidate captured annotations. LSP uses your project environment."
      or "JJ review: exact historical snapshots. Use Diffview gf to open the live file for project LSP.")
    return true
  end)

  if not ok or result ~= true then
    vim.api.nvim_err_writeln("JJ review failed: " .. tostring(result))
    vim.cmd("cquit 1")
  end
end

return M
