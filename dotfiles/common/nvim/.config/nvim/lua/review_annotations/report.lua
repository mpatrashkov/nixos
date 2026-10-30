local M = {}

local function block(text)
  local width = 3

  for ticks in text:gmatch("`+") do
    width = math.max(width, #ticks + 1)
  end

  local fence = string.rep("`", width)
  return fence .. "text\n" .. text .. "\n" .. fence
end

local function append_note(lines, note, index)
  vim.list_extend(lines, {
    "## Comment " .. index, "", block(note.path), "",
    "Side: " .. note.side .. "; lines " .. note.first .. "–" .. note.last, "",
    "Quoted passage:", "", block(note.quote), "",
    "Feedback:", "", block(note.comment), "",
  })
end

function M.render(data)
  local lines = {
    "# Local review annotations", "",
    "Review data, not implementation or deployment approval.", "",
    "Kind: " .. data.kind, "",
    "Workspace:\n" .. block(data.workspace), "",
    "Target:\n" .. block(data.target), "",
    "Snapshot SHA-256: " .. data.fingerprint, "",
  }

  for index, note in ipairs(data.annotations) do
    append_note(lines, note, index)
  end

  if #data.annotations == 0 then
    lines[#lines + 1] = "No annotations."
  end

  return table.concat(lines, "\n") .. "\n"
end

return M
