-- Invoked after the real JJ launcher opens Diffview in a disposable repository.
vim.defer_fn(function()
  local ok, err = pcall(function()
    if vim.env.JJ_REVIEW_MODE == "legacy" then
      local legacy = require("review_annotations.jj")
      assert(legacy.interface and legacy.tree)
      assert(vim.wait(5000, function() return next(legacy.interface.buffers) ~= nil end, 20))
      assert(vim.fn.isdirectory(vim.env.JJ_REVIEW_LEFT) == 1)
      vim.fn.writefile({ "PASS legacy" }, vim.env.JJ_REVIEW_TEST_RESULT)
      return
    end

    local adapter = require("review_annotations.diffview")
    assert(vim.wait(10000, function()
      return adapter.view and vim.tbl_count(adapter.interface.buffers) >= 2
    end, 20), "Annotation panes did not mount")
    local view = adapter.view
    local interface = adapter.interface
    assert(vim.fn.getcwd() == vim.env.JJ_REVIEW_ROOT)
    view:set_file_by_path("src/main.zig", false, true)
    assert(vim.wait(5000, function()
      return view.cur_layout.a.file.path == "src/main.zig"
        and interface.buffers[view.cur_layout.b.file.bufnr] ~= nil
    end, 20), "Main Zig file did not mount")
    local before = view.cur_layout.a.file.bufnr
    local after = view.cur_layout.b.file.bufnr
    assert(interface.buffers[before].side == "before")
    assert(interface.buffers[after].side == "after")
    assert(vim.bo[before].buftype == "nowrite")
    assert(vim.bo[before].modifiable == false)
    assert(vim.treesitter.query.get("zig", "highlights"))
    assert(vim.treesitter.highlighter.active[after])
    assert(vim.fn.isdirectory(vim.env.JJ_REVIEW_LEFT) == 1)

    -- Exercise additions, deletions, renamed paths, quoted/Unicode names, BOM/CRLF,
    -- and unsupported binary panes through the plugin's own file selector.
    for _, entry in view.files:iter() do
      view:set_file(entry, false, true)
      assert(vim.wait(5000, function() return view.cur_entry == entry end, 20))
      vim.wait(50, function() return false end)
      for _, symbol in ipairs({ "a", "b" }) do
        local file = view.cur_layout[symbol].file
        local side = symbol == "a" and "before" or "after"
        local item = interface.store:entry(file.path, side)
        if not file.nulled and not file.binary and item and item.lines then
          assert(interface.buffers[file.bufnr], "Missing supported anchor: " .. file.path .. " " .. vim.inspect({
            lines = vim.api.nvim_buf_get_lines(file.bufnr, 0, -1, false),
            expected = item.lines, bomb = vim.bo[file.bufnr].bomb, ff = vim.bo[file.bufnr].fileformat,
          }))
          local passage = interface.store:create(file.path, side, 1, 1)
          adapter.jump(passage)
          assert(vim.api.nvim_get_current_buf() == file.bufnr)
        else
          assert(interface.buffers[file.bufnr] == nil, "Unsupported pane acquired an annotation anchor")
        end
      end
    end

    local note = interface.store:create("src/main.zig", "after", 1, 1)
    note.comment = "A retained regression test comment"
    interface.store:put(note, note.comment, false)
    interface.store:put(note, "Edited regression comment", true)
    assert(interface.store:write_report():find("Edited regression comment", 1, true))
    interface.store:remove(note.id)
    interface.store:put(note, note.comment, false)
    interface:refresh()
    adapter.jump(note)
    assert(vim.api.nvim_get_current_buf() == after)
    assert(interface:anchor().side == "after")
    assert(interface.store:write_report():find(note.comment, 1, true))

    if vim.env.JJ_REVIEW_MODE == "live" then
      assert(vim.bo[after].buftype == "")
      assert(vim.api.nvim_buf_get_name(after) == vim.fn.getcwd() .. "/src/main.zig")
      if vim.fn.executable("zls") == 1 then
        assert(vim.wait(15000, function()
          return #vim.lsp.get_clients({ bufnr = after, name = "zls" }) == 1
        end, 50), "Native ZLS did not attach to the working file")
        local client = vim.lsp.get_clients({ bufnr = after, name = "zls" })[1]
        assert(client.server_capabilities.hoverProvider)
        assert(client.server_capabilities.definitionProvider)
        local line = vim.api.nvim_buf_get_lines(after, 1, 2, false)[1]
        local params = {
          textDocument = { uri = vim.uri_from_bufnr(after) },
          position = { line = 1, character = assert(line:find("value", 1, true)) - 1 },
        }
        local hover = client:request_sync("textDocument/hover", params, 5000, after)
        assert(hover and hover.result, "Native ZLS hover failed")
        local definition = client:request_sync("textDocument/definition", params, 5000, after)
        assert(definition and definition.result and #definition.result > 0, "Native ZLS definition failed")
      end
      -- Reject annotations outside Diffview even if the real buffer is shared.
      vim.cmd("tabnew")
      vim.api.nvim_win_set_buf(0, after)
      assert(not pcall(function() interface:anchor() end))
      local namespace = vim.api.nvim_create_namespace("review_annotations")
      assert(#vim.api.nvim_buf_get_extmarks(after, namespace, 0, -1, {}) == 0,
        "Annotation markers leaked into the project tab")
      vim.cmd("tabclose")
      vim.api.nvim_set_current_win(view.cur_layout.b.id)
      vim.api.nvim_buf_set_lines(after, 0, 1, false, { "// edited live content" })
      vim.wait(50, function() return false end)
      assert(not pcall(function() interface:anchor() end))
      adapter.mount(after, view.cur_layout.b.id, { symbol = "b" })
      vim.wait(50, function() return false end)
      assert(not pcall(function() interface:anchor() end), "Mount reset stale anchor")
      assert(not pcall(function() adapter.jump(note) end), "Stale jump succeeded")
      assert(not pcall(vim.cmd, "qa"), "Quit discarded modified live buffer")
    else
      assert(vim.bo[after].buftype == "nowrite")
      assert(vim.bo[after].modifiable == false)
      assert(#vim.lsp.get_clients({ bufnr = after }) == 0)
    end

    require("diffview").close()
    assert(adapter.view == nil)
    assert(next(interface.buffers) == nil)
    if vim.api.nvim_buf_is_valid(after) then
      local mapping = vim.api.nvim_buf_call(after, function()
        return vim.fn.maparg("<leader>ra", "n", false, true)
      end)
      assert(vim.tbl_isempty(mapping), "Annotation mapping leaked after view close")
    end
    assert(not pcall(function() adapter.jump(note) end))
    assert(vim.fn.exists(":ReviewReport") == 2)
    vim.fn.writefile({ "PASS " .. vim.env.JJ_REVIEW_MODE }, vim.env.JJ_REVIEW_TEST_RESULT)
  end)
  if not ok then
    vim.fn.writefile({ tostring(err), debug.traceback() }, vim.env.JJ_REVIEW_TEST_RESULT)
  end
  vim.cmd("qa!")
end, 200)
