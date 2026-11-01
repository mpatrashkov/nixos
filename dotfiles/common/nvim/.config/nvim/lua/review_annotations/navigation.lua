local M = {}

function M.jump(buf, direction, count)
  local heading_query = vim.treesitter.query.parse("markdown", [[
    [(atx_heading) (setext_heading)] @heading
  ]])
  local parser = vim.treesitter.get_parser(buf, "markdown")
  local tree = parser:parse()[1]
  local headings = {}

  for _, node in heading_query:iter_captures(tree:root(), buf) do
    local row = node:start()
    table.insert(headings, row + 1)
  end

  local row = vim.api.nvim_win_get_cursor(0)[1]
  local destination = row
  local remaining = count

  if direction < 0 then
    for index = #headings, 1, -1 do
      if headings[index] < row then
        destination = headings[index]
        remaining = remaining - 1
        if remaining == 0 then
          break
        end
      end
    end
  else
    for _, heading in ipairs(headings) do
      if heading > row then
        destination = heading
        remaining = remaining - 1
        if remaining == 0 then
          break
        end
      end
    end
  end

  vim.api.nvim_win_set_cursor(0, { destination, 0 })
  vim.cmd("normal! zv")
end

function M.window()
  vim.wo.number = true
  vim.wo.relativenumber = false
  vim.wo.foldmethod = "expr"
  vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
  vim.wo.foldtext = ""
  vim.wo.foldcolumn = "1"
  vim.wo.foldenable = true
  vim.wo.foldlevel = 99
end

function M.setup(buf)
  M.window()

  vim.keymap.set("n", "]h", function()
    M.jump(buf, 1, vim.v.count1)
  end, { buffer = buf, desc = "Next plan heading (reveal fold)" })

  vim.keymap.set("n", "[h", function()
    M.jump(buf, -1, vim.v.count1)
  end, { buffer = buf, desc = "Previous plan heading (reveal fold)" })
end

return M
