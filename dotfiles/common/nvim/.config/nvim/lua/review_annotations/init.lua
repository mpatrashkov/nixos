local files = require("review_annotations.files")
local snapshot = require("review_annotations.snapshot")
local Store = require("review_annotations.store")
local UI = require("review_annotations.ui")

local M = {}

local function finish_review(interface, result_path)
  local store = interface.store
  local ok, result = pcall(function()
    local buf = interface.draft_buf
    assert(not buf or not vim.api.nvim_buf_is_valid(buf), "Unfinished comment draft; approval withheld")
    return store:finish()
  end)

  local closed, err = pcall(function() store:close() end)

  if not ok or not closed then
    vim.api.nvim_err_writeln("Review annotations: " .. tostring(err or result))
    return
  end

  if result_path and vim.v.exiting == 0 then
    local content = vim.json.encode(result)
    assert(#content <= 16384, "Review receipt too large")
    files.atomic(result_path, content)
  end
end

function M.install(store, jump, result_path)
  assert(not M.current, "A review session is already active")

  local ok, interface = pcall(UI.new, store, jump)
  if not ok then
    store:close()
    error(interface)
  end

  M.current = interface

  vim.api.nvim_create_autocmd("VimLeavePre", {
    once = true,
    callback = UI.guard(function() finish_review(interface, result_path) end),
  })

  return interface
end

local function jump_to_plan(buf, note)
  assert(vim.api.nvim_buf_is_valid(buf), "Plan source buffer is closed")
  local win = vim.fn.bufwinid(buf)

  if win == -1 then
    vim.cmd("split")
    vim.api.nvim_win_set_buf(0, buf)
  else
    vim.api.nvim_set_current_win(win)
  end

  vim.api.nvim_win_set_cursor(0, { note.first, 0 })
end

function M.plan()
  local ok, err = pcall(function()
    local encoded = assert(vim.env.PI_REVIEW_METADATA, "Missing review metadata")
    local metadata = vim.json.decode(encoded)
    local buf = vim.api.nvim_get_current_buf()
    local identity, entries = snapshot.plan(buf, metadata)
    local store = Store.open(identity, entries)

    local interface = M.install(store, function(note)
      jump_to_plan(buf, note)
    end, metadata.result)

    interface:attach(buf, metadata.path, "plan")
    vim.keymap.set("n", "q", "<cmd>qa<cr>", { buffer = buf, desc = "Return to Pi" })
  end)

  if not ok then
    vim.api.nvim_err_writeln("Plan annotations failed: " .. tostring(err))
    vim.cmd("cquit 1")
  end
end

return M
