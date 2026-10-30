local M = {}
local ns = vim.api.nvim_create_namespace("review_annotations")

function M.guard(callback)
  return function(...)
    local ok, err = pcall(callback, ...)
    if not ok then
      vim.notify("Review annotations: " .. tostring(err), vim.log.levels.ERROR)
    end
  end
end

function M.new(store, jump)
  local self = { store = store, buffers = {}, jump = jump }

  function self.refresh()
    for buf, anchor in pairs(self.buffers) do
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
        for _, note in ipairs(store.data.annotations) do
          if note.path == anchor.path and note.side == anchor.side then
            vim.api.nvim_buf_set_extmark(buf, ns, note.first - 1, 0, {
              end_row = note.last, hl_group = "Visual", hl_eol = true,
              sign_text = "◆", sign_hl_group = "DiagnosticInfo",
              virt_text = { { " review comment", "DiagnosticInfo" } },
            })
          end
        end
      end
    end
  end

  function self.persist(notes)
    store.save(notes)
    self.refresh()
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
        M.guard(callback)(note)
      end
    end)
  end

  function self.draft(note, existing)
    if self.draft_buf and vim.api.nvim_buf_is_valid(self.draft_buf) then
      local win = vim.fn.bufwinid(self.draft_buf)
      if win == -1 then
        vim.cmd("split")
        vim.api.nvim_win_set_buf(0, self.draft_buf)
      else
        vim.api.nvim_set_current_win(win)
      end
      vim.notify("Finish the existing draft first (:w saves, q cancels)")
      return
    end
    local buf = vim.api.nvim_create_buf(false, true)
    self.draft_buf = buf
    vim.bo[buf].buftype = "acwrite"
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].swapfile = false
    vim.bo[buf].readonly = false
    vim.bo[buf].filetype = "text"
    vim.api.nvim_buf_set_name(buf, "review-comment://" .. note.id)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(note.comment, "\n", { plain = true }))
    vim.bo[buf].modified = false
    local width = math.max(20, math.min(90, vim.o.columns - 4))
    local height = math.max(3, math.min(12, vim.o.lines - 6))
    vim.api.nvim_open_win(buf, true, {
      relative = "editor", width = width, height = height,
      row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
      col = math.max(0, math.floor((vim.o.columns - width) / 2)),
      style = "minimal", border = "rounded", title = " Comment · :w save · q cancel ",
    })
    local function close()
      vim.cmd("stopinsert")
      vim.api.nvim_buf_delete(buf, { force = true })
      self.draft_buf = nil
    end
    local save = M.guard(function()
      local text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
      assert(text:find("%S"), "Empty comment: cancel instead, or delete the saved comment")
      assert(#text <= 65536, "Comment exceeds 64 KiB")
      local saved = vim.deepcopy(note)
      saved.comment = text
      saved.updated = os.date("!%Y-%m-%dT%H:%M:%SZ")
      local notes = vim.deepcopy(store.data.annotations)
      local replaced = false
      for i, other in ipairs(notes) do
        if other.id == saved.id then
          notes[i] = saved
          replaced = true
        end
      end
      if not replaced then
        assert(not existing, "Annotation was removed")
        notes[#notes + 1] = saved
      end
      self.persist(notes)
      vim.bo[buf].modified = false
      close()
    end)
    vim.api.nvim_create_autocmd("BufWriteCmd", { buffer = buf, callback = save })
    vim.keymap.set({ "n", "i" }, "<C-s>", save, { buffer = buf, desc = "Save review comment" })
    vim.keymap.set("n", "q", function()
      if vim.bo[buf].modified and vim.fn.confirm("Discard comment draft?", "&Keep editing\n&Discard", 1) ~= 2 then
        return
      end
      close()
    end, { buffer = buf, desc = "Cancel comment draft" })
  end

  function self.add(visual)
    local buf = vim.api.nvim_get_current_buf()
    local anchor = assert(self.buffers[buf], "Not an annotatable review source buffer")
    local first = vim.api.nvim_win_get_cursor(0)[1]
    local last = first
    if visual then
      first = vim.fn.line("v")
      last = vim.fn.line(".")
      if first > last then
        first, last = last, first
      end
      -- Exit visual mode before opening the comment window.
      vim.cmd.normal({ args = { "\27" }, bang = true })
    end
    local entry = store.lookup[anchor.side .. "\0" .. anchor.path]
    assert(vim.deep_equal(vim.api.nvim_buf_get_lines(buf, 0, -1, false), entry and entry.lines), "Pane is not a verified text snapshot")
    local quote = require("review_annotations.store").quote(entry, first, last)
    local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    self.draft({
      version = 1, id = tostring(vim.uv.os_getpid()) .. "-" .. tostring(vim.uv.hrtime()),
      fingerprint = store.data.fingerprint, created = timestamp, updated = timestamp,
      path = anchor.path, side = anchor.side, first = first, last = last, quote = quote, comment = "",
    }, false)
  end

  function self.list()
    pick(store.data.annotations, self.jump)
  end

  local function at_cursor(callback)
    local anchor = assert(self.buffers[vim.api.nvim_get_current_buf()], "Not a review source buffer")
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local notes = {}
    for _, note in ipairs(store.data.annotations) do
      if note.path == anchor.path and note.side == anchor.side and note.first <= row and note.last >= row then
        notes[#notes + 1] = note
      end
    end
    pick(notes, callback)
  end

  function self.edit()
    at_cursor(function(note)
      self.draft(note, true)
    end)
  end

  function self.delete()
    at_cursor(function(note)
      if vim.fn.confirm("Delete this annotation?", "&Keep\n&Delete", 1) ~= 2 then
        return
      end
      local notes = {}
      for _, other in ipairs(store.data.annotations) do
        if other.id ~= note.id then
          notes[#notes + 1] = other
        end
      end
      self.persist(notes)
    end)
  end

  function self.report()
    require("review_annotations.store").atomic(store.report, require("review_annotations.store").report(store.data))
    local content = require("review_annotations.store").read(store.report)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, "\n", { plain = true }))
    vim.bo[buf].filetype = "markdown"
    vim.bo[buf].modifiable = false
    vim.bo[buf].readonly = true
    vim.bo[buf].bufhidden = "wipe"
    vim.cmd("botright split")
    vim.api.nvim_win_set_buf(0, buf)
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf })
    vim.notify("Local review report: " .. store.report)
  end

  function self.attach(buf, path, side)
    local entry = store.lookup[side .. "\0" .. path]
    self.buffers[buf] = { path = path, side = side }
    local function map(mode, key, action, desc)
      vim.keymap.set(mode, key, M.guard(action), { buffer = buf, desc = desc })
    end
    map("n", "<leader>ra", function() self.add(false) end, "Add review comment")
    map("x", "<leader>ra", function() self.add(true) end, "Annotate selected lines")
    map("n", "<leader>rl", self.list, "List review comments")
    map("n", "<leader>re", self.edit, "Edit review comment")
    map("n", "<leader>rd", self.delete, "Delete review comment")
    map("n", "<leader>rr", self.report, "Open local review report")
    if not entry or not entry.lines then
      -- Keep actions discoverable; add() rejects unsupported/absent text.
      return
    end
    assert(vim.deep_equal(vim.api.nvim_buf_get_lines(buf, 0, -1, false), entry.lines), "Viewer text differs from comparison manifest")
    self.refresh()
  end

  vim.api.nvim_create_user_command("ReviewHelp", function()
    vim.notify("Review only: <leader>ra add (normal/visual), rl list/jump, re edit, rd delete, rr report.\n"
      .. "Comment window: :w or Ctrl-s saves; q cancels (prompts for edits). Reports are local, not approval.\n"
      .. store.report)
  end, {})
  return self
end

return M
