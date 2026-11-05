-- The only version-bound Diffview accessors live here. UI and LSP stay in Diffview.
local snapshot = require("review_annotations.snapshot")
local Store = require("review_annotations.store")
local UI = require("review_annotations.ui")
local M = {}

local function current_view()
  return require("diffview.lib").get_current_view()
end

local function pane(view, buf, symbol)
  assert(symbol == "a" or symbol == "b", "Unsupported Diffview layout symbol")
  local layout = assert(view.cur_layout, "Missing Diffview layout")
  local window = assert(layout[symbol], "Missing Diffview pane")
  local file = assert(window.file, "Missing Diffview file metadata")
  assert(file.bufnr == buf, "Diffview buffer metadata mismatch")
  assert(type(file.path) == "string", "Missing Diffview logical path")
  return file, window
end

function M.start(root, left, right)
  local identity, entries = snapshot.jj(root, left, right)
  M.root = root
  M.tracked = {}
  M.claimed = false
  M.entries = entries
  M.interface = require("review_annotations").install(Store.open(identity, entries), M.jump)
  M.interface.context = function()
    if not M.view or current_view() ~= M.view then
      return false
    end

    local buf = vim.api.nvim_get_current_buf()
    local anchor = M.interface.buffers[buf]
    if not anchor then
      return false
    end

    local symbol = anchor.side == "before" and "a" or "b"
    local _, window = pane(M.view, buf, symbol)
    return window.id == vim.api.nvim_get_current_win()
  end

  vim.api.nvim_create_user_command("ReviewList", UI.guard(function() M.interface:list() end), {})
  vim.api.nvim_create_user_command("ReviewReport", UI.guard(function() M.interface:report() end), {})
end

function M.opened(view)
  if not M.interface or M.claimed then
    return
  end

  assert(view.adapter and view.adapter.ctx.toplevel == M.root, "Diffview workspace mismatch")
  assert(type(view.set_file) == "function" and view.files, "Unsupported Diffview file API")
  M.claimed = true
  M.view = view
  vim.keymap.set("n", "<leader>rl", UI.guard(function() M.interface:list() end), {
    buffer = view.panel.bufid, desc = "List review comments",
  })
  vim.keymap.set("n", "<leader>rr", UI.guard(function() M.interface:report() end), {
    buffer = view.panel.bufid, desc = "Open local review report",
  })

  -- A JJ-tracked path can be invisible to Git's working-tree enumeration (for
  -- example, when Git's index and ignore rules differ). Never omit it silently.
  view.emitter:once("files_updated", function(_, files)
    local visible = {}
    for _, entry in files:iter() do
      for _, symbol in ipairs({ "a", "b" }) do
        local window = entry.layout[symbol]
        if window and window.file then
          local side = symbol == "a" and "before" or "after"
          visible[side .. "\0" .. window.file.path] = true
        end
      end
    end
    for _, item in ipairs(M.entries) do
      if not visible[item.side .. "\0" .. item.path] then
        vim.schedule(function()
          view:close()
          vim.notify("JJ review rejected: Diffview omitted " .. item.path .. ". Use jj review-legacy for this comparison.", vim.log.levels.ERROR)
        end)
        return
      end
    end
  end)
end

local function decoded_lines(item, buf)
  local lines = vim.deepcopy(item.lines)
  if vim.bo[buf].bomb then
    lines[1] = lines[1]:gsub("^\239\187\191", "")
  end
  -- Diffview's Git job reader strips CR line endings before populating nowrite
  -- buffers; unlike an ordinary file read, it does not set 'fileformat'.
  if vim.bo[buf].fileformat == "dos" or vim.bo[buf].buftype == "nowrite" then
    for index, line in ipairs(lines) do
      lines[index] = line:gsub("\r$", "")
    end
  end
  return lines
end

function M.mount(buf, win, context)
  -- Diffview emits this after its own mappings are installed. Defer annotation
  -- work out of plugin callbacks; errors must not break the plugin's scheduler.
  vim.schedule(UI.guard(function()
    if not M.view or current_view() ~= M.view or not vim.api.nvim_win_is_valid(win) then
      return
    end

    local file = pane(M.view, buf, context.symbol)
    if file.nulled or file.binary then
      return
    end

    local side = context.symbol == "a" and "before" or "after"
    local item = M.interface.store:entry(file.path, side)
    if not item or not item.lines then
      return
    end

    local tracked = M.tracked[buf]
    if tracked then
      assert(tracked.path == file.path and tracked.side == side, "Diffview reused an annotation buffer ambiguously")
      return
    end

    local lines = decoded_lines(item, buf)
    if not vim.deep_equal(vim.api.nvim_buf_get_lines(buf, 0, -1, false), lines) then
      vim.notify("Review annotations unavailable: " .. file.path .. " differs from the captured comparison. Reopen jj review to refresh.", vim.log.levels.WARN)
      return
    end

    M.interface:attach(buf, file.path, side, lines)
    M.tracked[buf] = { path = file.path, side = side }
    vim.api.nvim_buf_attach(buf, false, {
      on_lines = function()
        -- Invalidation is permanent for this buffer/session, even after undo.
        -- A later pane mount must not bless a changed tick as a fresh anchor.
        vim.schedule(function()
          if M.interface and M.interface.buffers[buf] then
            M.interface:refresh()
          end
        end)
      end,
      on_detach = function()
        M.tracked[buf] = nil
        if M.interface then
          M.interface:detach(buf)
        end
      end,
    })
  end))
end

function M.jump(note)
  local view = assert(M.view, "Review view is closed; report still retains the captured passage")
  assert(vim.api.nvim_tabpage_is_valid(view.tabpage), "Review tab is closed")
  vim.api.nvim_set_current_tabpage(view.tabpage)

  local target
  local symbol = note.side == "before" and "a" or "b"
  -- FileEntry/layout/file is the pinned plugin's structured file model. Use its
  -- own selection method; do not duplicate its file-opening implementation.
  for _, entry in view.files:iter() do
    local window = entry.layout[symbol]
    if window and window.file and window.file.path == note.path then
      target = entry
      break
    end
  end
  assert(target, "Annotated file is no longer in this view; reopen jj review")
  view:set_file(target, false, true)
  local ready = vim.wait(3000, function()
    if view.cur_entry ~= target then
      return false
    end
    local window = view.cur_layout[symbol]
    return window and window.file and M.interface.buffers[window.file.bufnr] ~= nil
  end, 10)
  assert(ready, "Annotated pane is absent or changed; reopen jj review to refresh")

  local window = view.cur_layout[symbol]
  vim.api.nvim_set_current_win(window.id)
  local anchor = M.interface:anchor()
  assert(anchor.path == note.path and anchor.side == note.side, "Annotation target mismatch")
  vim.api.nvim_win_set_cursor(window.id, { note.first, 0 })
end

function M.visibility(view, visible)
  if view ~= M.view then
    return
  end

  M.interface.visible = visible
  M.interface:refresh()
end

function M.closed(view)
  if view ~= M.view then
    return
  end

  M.view = nil
  for buf in pairs(M.interface.buffers) do
    M.interface:detach(buf)
  end
end

return M
