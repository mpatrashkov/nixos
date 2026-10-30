local M = {}

function M.focus(buf)
  local win = vim.fn.bufwinid(buf)

  if win == -1 then
    vim.cmd("split")
    vim.api.nvim_win_set_buf(0, buf)
  else
    vim.api.nvim_set_current_win(win)
  end
end

local function open_window(buf)
  local width = math.max(20, math.min(90, vim.o.columns - 4))
  local height = math.max(3, math.min(12, vim.o.lines - 6))

  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
    col = math.max(0, math.floor((vim.o.columns - width) / 2)),
    style = "minimal",
    border = "rounded",
    title = " Comment · :w save · q cancel ",
  })
end

local function create_buffer(note)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "acwrite"
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].swapfile = false
  vim.bo[buf].readonly = false
  vim.bo[buf].filetype = "text"

  vim.api.nvim_buf_set_name(buf, "review-comment://" .. note.id)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(note.comment, "\n", { plain = true }))
  vim.bo[buf].modified = false
  return buf
end

function M.open(note, on_save, on_close)
  local buf = create_buffer(note)
  open_window(buf)

  local function close()
    vim.cmd("stopinsert")
    vim.api.nvim_buf_delete(buf, { force = true })
    on_close()
  end

  local function save()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local ok, err = pcall(on_save, table.concat(lines, "\n"))

    if not ok then
      vim.notify("Review annotations: " .. tostring(err), vim.log.levels.ERROR)
      return
    end

    vim.bo[buf].modified = false
    close()
  end

  local function cancel()
    if vim.bo[buf].modified then
      local choice = vim.fn.confirm("Discard comment draft?", "&Keep editing\n&Discard", 1)
      if choice ~= 2 then
        return
      end
    end

    close()
  end

  vim.api.nvim_create_autocmd("BufWriteCmd", { buffer = buf, callback = save })
  vim.keymap.set({ "n", "i" }, "<C-s>", save, { buffer = buf, desc = "Save review comment" })
  vim.keymap.set("n", "q", cancel, { buffer = buf, desc = "Cancel comment draft" })

  vim.cmd("startinsert")
  return buf
end

return M
