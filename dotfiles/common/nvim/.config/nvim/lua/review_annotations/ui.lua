local draft = require("review_annotations.draft")
local namespace = vim.api.nvim_create_namespace("review_annotations")

local UI = {}
UI.__index = UI

function UI.guard(callback)
  return function(...)
    local ok, err = pcall(callback, ...)

    if not ok then
      vim.notify("Review annotations: " .. tostring(err), vim.log.levels.ERROR)
    end
  end
end

local function pick(notes, callback)
  if #notes == 0 then
    vim.notify("No annotations here")
    return
  end

  vim.ui.select(notes, {
    prompt = "Review annotations",
    format_item = function(note)
      local summary = vim.fn.strcharpart(note.comment:gsub("\n", " "), 0, 100)
      return string.format("%s [%s:%d–%d] %s", note.path, note.side, note.first, note.last, summary)
    end,
  }, function(note)
    if note then
      UI.guard(callback)(note)
    end
  end)
end

local function selected_lines(visual)
  local first = vim.api.nvim_win_get_cursor(0)[1]
  local last = first

  if visual then
    first, last = vim.fn.line("v"), vim.fn.line(".")
    vim.cmd.normal({ args = { "\27" }, bang = true })
  end

  return math.min(first, last), math.max(first, last)
end

function UI.new(store, jump)
  local self = setmetatable({ store = store, jump = jump, buffers = {} }, UI)

  vim.api.nvim_create_user_command("ReviewHelp", function() self:help() end, {})
  return self
end

function UI:help()
  vim.notify("Review only: <leader>ra add (normal/visual), rl list/jump, re edit, rd delete, rr report.\n"
    .. "Comment window: :w or Ctrl-s saves; q cancels (prompts for edits). Reports are local, not approval.\n"
    .. self.store.report)
end

local function mark_passage(buf, note)
  vim.api.nvim_buf_set_extmark(buf, namespace, note.first - 1, 0, {
    end_row = note.last,
    hl_group = "Visual",
    hl_eol = true,
    sign_text = "◆",
    sign_hl_group = "DiagnosticInfo",
    virt_text = { { " review comment", "DiagnosticInfo" } },
  })
end

local function refresh_buffer(buf, anchor, notes)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)

  if vim.api.nvim_buf_get_changedtick(buf) ~= anchor.tick then
    return
  end

  for _, note in ipairs(notes) do
    if note.path == anchor.path and note.side == anchor.side then
      mark_passage(buf, note)
    end
  end
end

function UI:refresh()
  for buf, anchor in pairs(self.buffers) do
    refresh_buffer(buf, anchor, self.store.data.annotations)
  end
end

function UI:anchor()
  local buf = vim.api.nvim_get_current_buf()
  local anchor = assert(self.buffers[buf], "Not an annotatable review source buffer")

  assert(anchor.tick == vim.api.nvim_buf_get_changedtick(buf), "Review source buffer changed")
  return anchor
end

function UI:resume_draft()
  if not self.draft_buf or not vim.api.nvim_buf_is_valid(self.draft_buf) then
    return false
  end

  draft.focus(self.draft_buf)
  vim.notify("Finish the existing draft first (:w saves, q cancels)")
  return true
end

function UI:open_draft(note, existing)
  if self:resume_draft() then
    return
  end

  self.draft_buf = draft.open(note, function(comment)
    self.store:put(note, comment, existing)
    self:refresh()
  end, function()
    self.draft_buf = nil
  end)
end

function UI:add(visual)
  if self:resume_draft() then
    return
  end

  local anchor = self:anchor()
  local first, last = selected_lines(visual)
  local note = self.store:create(anchor.path, anchor.side, first, last)

  self:open_draft(note, false)
end

function UI:list()
  pick(self.store.data.annotations, self.jump)
end

function UI:notes_at_cursor()
  local anchor = self:anchor()
  local row = vim.api.nvim_win_get_cursor(0)[1]

  return self.store:at(anchor.path, anchor.side, row)
end

function UI:edit()
  if self:resume_draft() then
    return
  end

  pick(self:notes_at_cursor(), function(note)
    self:open_draft(note, true)
  end)
end

function UI:delete()
  pick(self:notes_at_cursor(), function(note)
    if vim.fn.confirm("Delete this annotation?", "&Keep\n&Delete", 1) ~= 2 then
      return
    end

    self.store:remove(note.id)
    self:refresh()
  end)
end

function UI:report()
  local content = self.store:write_report()
  local buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, "\n", { plain = true }))
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true
  vim.bo[buf].bufhidden = "wipe"

  vim.cmd("botright split")
  vim.api.nvim_win_set_buf(0, buf)
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf })
  vim.notify("Local review report: " .. self.store.report)
end

function UI:attach(buf, path, side)
  local item = self.store:entry(path, side)

  if item and item.lines then
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    assert(vim.deep_equal(lines, item.lines), "Pane differs from verified snapshot")
  end

  self.buffers[buf] = { path = path, side = side, tick = vim.api.nvim_buf_get_changedtick(buf) }

  local function map(mode, key, action, description)
    vim.keymap.set(mode, key, UI.guard(action), { buffer = buf, desc = description })
  end

  map("n", "<leader>ra", function() self:add(false) end, "Add review comment")
  map("x", "<leader>ra", function() self:add(true) end, "Annotate selected lines")
  map("n", "<leader>rl", function() self:list() end, "List review comments")
  map("n", "<leader>re", function() self:edit() end, "Edit review comment")
  map("n", "<leader>rd", function() self:delete() end, "Delete review comment")
  map("n", "<leader>rr", function() self:report() end, "Open local review report")

  self:refresh()
end

return UI
