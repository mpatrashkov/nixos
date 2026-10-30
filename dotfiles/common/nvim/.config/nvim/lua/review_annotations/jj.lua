-- Compatibility adapter for the pinned hunk.nvim read-only viewer.
-- Only documented mount hooks are installed; no plugin functions are replaced.
local M = {}
local store = require("review_annotations.store")

function M.start(left, right)
  local result = vim.system({ "jj", "--ignore-working-copy", "root" }, { text = true }):wait()
  assert(result.code == 0, result.stderr)
  local workspace = store.canonical(result.stdout:gsub("\n$", ""))
  local entries = store.scan(left, "before")
  vim.list_extend(entries, store.scan(right, "after"))
  local fingerprint = store.hash(vim.json.encode(store.manifest(entries)))
  local session = store.open({ kind = "jj", workspace = workspace, target = "directory comparison", fingerprint = fingerprint }, entries)
  M.windows = {}
  M.interface = require("review_annotations").install(session, M.jump)
end

function M.tree_mount(context)
  if not M.interface then
    return
  end
  assert(type(context.opts.on_open) == "function", "Unsupported hunk tree hook")
  M.tree = context
  M.prefix = assert(vim.api.nvim_buf_get_name(context.buf):match("^(hunk://view/[^/]+/)tree$"), "Unsupported hunk tree buffer")
  -- Source-only annotation actions; sidebar gets only discovery/list/report.
  vim.keymap.set("n", "<leader>rl", M.interface.list, { buffer = context.buf, desc = "List review comments" })
  vim.keymap.set("n", "<leader>rr", require("review_annotations.ui").guard(M.interface.report), {
    buffer = context.buf, desc = "Open local review report",
  })
end

function M.diff_mount(context)
  if not M.interface then
    return
  end
  local name = vim.api.nvim_buf_get_name(context.buf)
  assert(M.prefix and name:sub(1, #M.prefix) == M.prefix, "Unexpected hunk review buffer")
  local side, path = name:sub(#M.prefix + 1):match("^([^/]+)/(.*)$")
  assert((side == "left" or side == "right") and path ~= "", "Unsupported hunk diff buffer")
  local logical_side = side == "left" and "before" or "after"
  M.windows[logical_side] = context.win
  M.interface.attach(context.buf, path, logical_side)
end

function M.jump(note)
  assert(M.tree, "Hunk file tree is unavailable")
  local function find(nodes)
    for _, node in ipairs(nodes) do
      if node.change and node.change.filepath == note.path then
        return node.change
      end
      local children = {}
      for _, id in ipairs(node:get_child_ids()) do
        children[#children + 1] = M.tree.tree:get_node(id)
      end
      local found = find(children)
      if found then
        return found
      end
    end
  end
  local change = assert(find(M.tree.tree:get_nodes()), "Annotated file is missing from hunk tree")
  -- The hook's on_open is the viewer's own navigation callback. It creates
  -- both read-only panes and runs mount hooks, just like pressing Enter.
  M.tree.opts.on_open(change, {})
  local win = assert(M.windows[note.side], "Annotated side is unavailable")
  assert(vim.api.nvim_win_is_valid(win), "Diff window was closed")
  vim.api.nvim_set_current_win(win)
  vim.api.nvim_win_set_cursor(win, { note.first, 0 })
end

return M
