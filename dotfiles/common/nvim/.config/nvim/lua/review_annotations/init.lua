local M = {}
local store = require("review_annotations.store")
local ui = require("review_annotations.ui")

function M.install(session, jump, result_path)
  assert(not M.current, "A review session is already active")
  local interface = ui.new(session, jump)
  M.current = interface
  vim.api.nvim_create_autocmd("VimLeavePre", {
    once = true,
    callback = function()
      local ok, err = pcall(function()
        local draft = interface.draft_buf
        assert(not draft or not vim.api.nvim_buf_is_valid(draft), "Unfinished comment draft; feedback and approval withheld")
        store.atomic(session.report, store.report(session.data))
        if result_path and vim.v.exiting == 0 then
          store.atomic(result_path, vim.json.encode({
            version = 1, path = session.data.target, sha256 = session.data.fingerprint,
            report = session.report, reportSha256 = store.hash(store.read(session.report)),
            count = #session.data.annotations,
          }))
        end
      end)
      session.close()
      if not ok then
        vim.api.nvim_err_writeln("Review annotations: " .. tostring(err))
      end
    end,
  })
  return interface
end

function M.plan()
  local ok, err = pcall(function()
    local encoded = assert(vim.env.PI_REVIEW_METADATA, "Missing review metadata")
    local metadata = vim.json.decode(encoded)
    assert(metadata.version == 1 and type(metadata.result) == "string", "Invalid review metadata")
    local target = store.canonical(metadata.path)
    assert(target == metadata.path, "Plan target is not canonical")
    local buf = vim.api.nvim_get_current_buf()
    local snapshot = vim.api.nvim_buf_get_name(buf)
    local entry = store.entry(snapshot, "plan", target)
    assert(entry.hash == metadata.sha256, "Plan snapshot hash mismatch")
    -- Neovim decodes BOM/CRLF on file read; identity still uses the raw bytes.
    if entry.lines then
      if vim.bo[buf].bomb then
        entry.lines[1] = entry.lines[1]:gsub("^\239\187\191", "")
      end
      if vim.bo[buf].fileformat == "dos" then
        for i, line in ipairs(entry.lines) do
          entry.lines[i] = line:gsub("\r$", "")
        end
      end
    end
    local workspace = store.canonical(metadata.workspace)
    local session = store.open({ kind = "plan", workspace = workspace, target = target, fingerprint = entry.hash }, { entry })
    local interface = M.install(session, function(note)
      assert(vim.api.nvim_buf_is_valid(buf), "Plan source buffer is closed")
      local win = vim.fn.bufwinid(buf)
      if win == -1 then
        vim.cmd("split")
        vim.api.nvim_win_set_buf(0, buf)
      else
        vim.api.nvim_set_current_win(win)
      end
      vim.api.nvim_win_set_cursor(0, { note.first, 0 })
    end, metadata.result)
    interface.attach(buf, target, "plan")
    vim.keymap.set("n", "q", "<cmd>qa<cr>", { buffer = buf, desc = "Return to Pi" })
  end)
  if not ok then
    vim.api.nvim_err_writeln("Plan annotations failed: " .. tostring(err))
    vim.cmd("cquit 1")
  end
end

return M
