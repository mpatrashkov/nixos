local M = {}
local files = require("review_annotations.files")
local uv = vim.uv

function M.valid_utf8(content)
  local position = 1
  local minimum = { 0, 0x80, 0x800, 0x10000 }

  while position <= #content do
    local first = content:byte(position)
    local length

    if first < 0x80 then
      length = 1
    elseif first >= 0xC2 and first <= 0xDF then
      length = 2
    elseif first >= 0xE0 and first <= 0xEF then
      length = 3
    elseif first >= 0xF0 and first <= 0xF4 then
      length = 4
    else
      return false
    end

    local codepoint = first % (2 ^ (7 - length))

    for offset = 1, length - 1 do
      local byte = content:byte(position + offset)
      if not byte or byte < 0x80 or byte > 0xBF then
        return false
      end
      codepoint = codepoint * 64 + byte - 0x80
    end

    if length > 1 and (codepoint < minimum[length] or codepoint > 0x10FFFF
      or (codepoint >= 0xD800 and codepoint <= 0xDFFF)) then
      return false
    end

    position = position + length
  end

  return true
end

local function text_lines(content)
  if content == "" or content:find("\0", 1, true) or not M.valid_utf8(content) then
    return nil
  end

  local lines = vim.split(content, "\n", { plain = true })
  if lines[#lines] == "" then
    table.remove(lines)
  end

  return lines
end

local function entry(path, side, logical)
  local info = assert(uv.fs_lstat(path))
  local result = { path = logical, side = side, kind = info.type }

  if info.type == "link" then
    result.hash = files.hash(assert(uv.fs_readlink(path)))
    return result
  end

  assert(info.type == "file", "Unsupported comparison entry: " .. path)

  if info.size > files.limit then
    result.hash = files.hash_file(path)
    return result
  end

  local content = files.read(path)
  result.hash = files.hash(content)
  result.lines = text_lines(content)
  return result
end

function M.scan(root, side)
  local entries = {}

  local function walk(relative)
    local scan = assert(uv.fs_scandir(root .. "/" .. relative))

    while true do
      local name = uv.fs_scandir_next(scan)
      if not name then
        break
      end

      assert(M.valid_utf8(name), "Unsupported filename encoding")
      local logical = relative .. name
      local path = root .. "/" .. logical

      if assert(uv.fs_lstat(path)).type == "directory" then
        walk(logical .. "/")
      else
        entries[#entries + 1] = entry(path, side, logical)
      end
    end
  end

  walk("")
  table.sort(entries, function(a, b) return a.path < b.path end)
  return entries
end

function M.manifest(entries)
  local manifest = {}

  for _, item in ipairs(entries) do
    manifest[#manifest + 1] = { item.side, item.path, item.kind, item.hash }
  end

  return manifest
end

function M.plan(buf, metadata)
  assert(metadata.version == 1, "Unsupported plan metadata")
  local target = assert(uv.fs_realpath(metadata.path))
  assert(target == metadata.path, "Plan target is not canonical")

  local item = entry(vim.api.nvim_buf_get_name(buf), "plan", target)
  assert(item.hash == metadata.sha256, "Plan snapshot hash mismatch")

  if item.lines then
    if vim.bo[buf].bomb then
      item.lines[1] = item.lines[1]:gsub("^\239\187\191", "")
    end

    if vim.bo[buf].fileformat == "dos" then
      for index, line in ipairs(item.lines) do
        item.lines[index] = line:gsub("\r$", "")
      end
    end
  end

  return { kind = "plan", workspace = metadata.workspace, target = target, fingerprint = item.hash }, { item }
end

function M.jj(workspace, left, right)
  local entries = M.scan(left, "before")
  vim.list_extend(entries, M.scan(right, "after"))

  local fingerprint = files.hash(vim.json.encode(M.manifest(entries)))
  return { kind = "jj", workspace = workspace, target = "directory comparison", fingerprint = fingerprint }, entries
end

function M.quote(item, first, last)
  assert(item and item.lines, "No supported text passage (absent, empty, binary, invalid UTF-8, symlink or oversized file)")
  assert(first >= 1 and last >= first and last <= #item.lines, "Invalid passage range")
  return table.concat(item.lines, "\n", first, last)
end

return M
