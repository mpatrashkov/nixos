local M = {}

-- Built-ins do not appear in nvim_get_keymap(). Keep this list intentionally small.
local basics = {
  { "n", "h j k l", "Movement", "Move left / down / up / right" },
  { "n", "w / b / e", "Movement", "Next word / previous word / end of word" },
  { "n", "0 / ^ / $", "Movement", "Start of line / first nonblank / end of line" },
  { "n", "gg / G", "Movement", "First / last line" },
  { "n", "<C-d> / <C-u>", "Movement", "Scroll half a page down / up" },
  { "n", "%", "Movement", "Jump to matching bracket" },
  { "n", "/ / ?", "Search", "Search forward / backward" },
  { "n", "n / N", "Search", "Next / previous search match" },
  { "n", "* / #", "Search", "Search word under cursor forward / backward" },
  { "n", "i / a", "Editing", "Insert before / after cursor" },
  { "n", "o / O", "Editing", "Insert new line below / above" },
  { "n", "u / <C-r>", "Editing", "Undo / redo" },
  { "n", ".", "Editing", "Repeat last change" },
  { "n", "dd / yy / p", "Editing", "Delete line / yank line / paste after" },
  { "n", "ciw / diw / yiw", "Editing", "Change / delete / yank inner word" },
  { "n", "v / V / <C-v>", "Selection", "Character / line / block selection" },
  { "x", "> / <", "Selection", "Indent / unindent selection" },
  { "n", "<C-w> h/j/k/l", "Windows", "Focus left / lower / upper / right window" },
  { "n", "<C-w> s / <C-w> v", "Windows", "Split horizontally / vertically" },
  { "n", "<C-w> q / <C-w> =", "Windows", "Close window / equalize window sizes" },
  { "n", ":w / :q / :wq", "Files", "Save / quit / save and quit" },
  { "n", ":bn / :bp / :bd", "Files", "Next buffer / previous buffer / delete buffer" },
  { "i", "<C-Space>", "Completion", "Request completion (nvim-cmp)" },
  { "i", "<CR> / <Tab>", "Completion", "Accept completion, including preselected item (nvim-cmp)" },
  { "i", "<C-e>", "Completion", "Dismiss completion (nvim-cmp)" },
  { "i", "<C-b> / <C-f>", "Completion", "Scroll completion documentation up / down (nvim-cmp)" },
  { "i", "<Esc>", "Modes", "Return to Normal mode" },
  { "t", "<C-\\><C-n>", "Modes", "Leave terminal input mode" },
  -- Review mappings are buffer-local; keep a reference visible outside reviews too.
  { "n", "<leader>ra", "Review only", "Add review comment on current line (Pi/JJ review)" },
  { "x", "<leader>ra", "Review only", "Annotate selected lines (Pi/JJ review)" },
  { "n", "<leader>rl", "Review only", "List / jump to review comments (Pi/JJ review)" },
  { "n", "<leader>re", "Review only", "Edit review comment (Pi/JJ review)" },
  { "n", "<leader>rd", "Review only", "Delete review comment (Pi/JJ review)" },
  { "n", "<leader>rr", "Review only", "Open local review report (Pi/JJ review)" },
  { "n", ":ReviewHelp", "Review only", "Show annotation help (Pi/JJ review)" },
  { "n/i", "<C-s>", "Review only", "Save comment (annotation draft only)" },
  { "n", "q", "Review only", "Cancel comment (annotation draft only)" },
}

function M.entries(buf)
  local entries = {}
  for _, basic in ipairs(basics) do
    table.insert(entries, {
      mode = basic[1],
      keys = basic[2],
      group = basic[3],
      description = basic[4],
    })
  end

  for _, mode in ipairs({ "n", "x", "s", "o", "i", "c", "t" }) do
    local mappings = {}
    for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
      mappings[map.lhs] = map
    end
    for _, map in ipairs(vim.api.nvim_buf_get_keymap(buf, mode)) do
      -- Even an undescribed local mapping shadows the global mapping.
      mappings[map.lhs] = map
    end

    for _, map in pairs(mappings) do
      if map.desc and map.desc ~= "" and not map.lhs:match("^<Plug>") then
        table.insert(entries, {
          mode = mode,
          keys = map.lhs,
          group = map.buffer == 0 and "Global maps" or "Buffer maps",
          description = map.desc,
        })
      end
    end
  end

  table.sort(entries, function(a, b)
    local left = table.concat({ a.group, a.keys, a.mode }, "\0")
    local right = table.concat({ b.group, b.keys, b.mode }, "\0")
    return left < right
  end)
  return entries
end

function M.open()
  -- Capture the source buffer before Telescope creates its prompt/results buffers.
  local entries = M.entries(vim.api.nvim_get_current_buf())
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local config = require("telescope.config").values
  local actions = require("telescope.actions")

  pickers.new({}, {
    prompt_title = "Shortcuts — Space is Leader · n=Normal x=Visual i=Insert t=Terminal",
    results_title = "Reference only · type to filter · Enter/Esc closes",
    previewer = false,
    layout_strategy = "horizontal",
    layout_config = { width = 0.95, height = 0.8 },
    finder = finders.new_table({
      results = entries,
      entry_maker = function(entry)
        local display = string.format(
          "%-12s  [%s]  %-24s  %s",
          entry.group, entry.mode, entry.keys, entry.description
        )
        return { value = entry, display = display, ordinal = display }
      end,
    }),
    sorter = config.generic_sorter({}),
    attach_mappings = function(_, map)
      -- This is a reference, not an action launcher (some mappings are destructive).
      actions.select_default:replace(actions.close)
      actions.select_horizontal:replace(actions.close)
      actions.select_vertical:replace(actions.close)
      actions.select_tab:replace(actions.close)
      map("i", "<Esc>", actions.close)
      map("n", "q", actions.close)
      return true
    end,
  }):find()
end

function M.setup()
  vim.api.nvim_create_user_command("Shortcuts", M.open, { desc = "Search shortcut reference" })
  vim.keymap.set("n", "<leader>?", M.open, { desc = "Search shortcut reference" })
end

return M
