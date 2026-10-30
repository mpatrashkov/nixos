-- Adapter for the pinned hunk.nvim viewer's documented mount hooks.
local snapshot = require("review_annotations.snapshot")
local Store = require("review_annotations.store")
local UI = require("review_annotations.ui")

local M = {}

function M.start(left, right)
  local result = vim.system({ "jj", "--ignore-working-copy", "root" }, { text = true }):wait()
  assert(result.code == 0, result.stderr)

  local workspace = result.stdout:gsub("\n$", "")
  local identity, entries = snapshot.jj(workspace, left, right)
  local store = Store.open(identity, entries)

  M.windows = {}
  M.interface = require("review_annotations").install(store, M.jump)
end

function M.tree_mount(context)
  if not M.interface then
    return
  end

  local name = vim.api.nvim_buf_get_name(context.buf)
  assert(type(context.opts.on_open) == "function", "Unsupported hunk tree hook")
  M.prefix = assert(name:match("^(hunk://view/[^/]+/)tree$"), "Unsupported hunk tree buffer")
  M.tree = context

  -- The sidebar offers discovery, but only source panes can be annotated.
  vim.keymap.set("n", "<leader>rl", UI.guard(function() M.interface:list() end), {
    buffer = context.buf, desc = "List review comments",
  })
  vim.keymap.set("n", "<leader>rr", UI.guard(function() M.interface:report() end), {
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
  M.interface:attach(context.buf, path, logical_side)
end

local function find_change(tree, nodes, path)
  for _, node in ipairs(nodes) do
    if node.change and node.change.filepath == path then
      return node.change
    end

    local children = {}

    for _, id in ipairs(node:get_child_ids()) do
      children[#children + 1] = tree:get_node(id)
    end

    local found = find_change(tree, children, path)
    if found then
      return found
    end
  end
end

function M.jump(note)
  local context = assert(M.tree, "Hunk file tree is unavailable")
  local change = find_change(context.tree, context.tree:get_nodes(), note.path)
  assert(change, "Annotated file is missing from hunk tree")

  -- Navigate through the viewer, never through a writable working file.
  context.opts.on_open(change, {})

  local win = assert(M.windows[note.side], "Annotated side is unavailable")
  assert(vim.api.nvim_win_is_valid(win), "Diff window was closed")
  vim.api.nvim_set_current_win(win)
  vim.api.nvim_win_set_cursor(win, { note.first, 0 })
end

return M
