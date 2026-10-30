local M = {}
local uv = vim.uv
local limit = 16 * 1024 * 1024

function M.read(path)
  local info = assert(uv.fs_lstat(path), "Cannot stat " .. path)
  assert(info.type == "file" and info.size <= limit, "Not a regular file <= 16 MiB: " .. path)
  local fd = assert(uv.fs_open(path, "r", 0))
  local content, err = uv.fs_read(fd, info.size, 0)
  uv.fs_close(fd)
  assert(content, err)
  assert(#content == info.size, "File changed or incomplete read: " .. path)
  return content
end

function M.hash(content)
  -- sha256sum accepts binary stdin without Vim string/NUL conversions.
  local result = vim.system({ "sha256sum" }, { stdin = content, text = true }):wait()
  assert(result.code == 0, result.stderr)
  return assert(result.stdout:match("^(%x+)"))
end

function M.canonical(path)
  return assert(uv.fs_realpath(path), "Cannot resolve " .. path)
end

function M.atomic(path, content)
  local temporary = path .. "." .. uv.os_getpid() .. ".tmp"
  local fd = assert(uv.fs_open(temporary, "wx", 384))
  local ok, err = pcall(function()
    assert(uv.fs_write(fd, content, 0) == #content, "Incomplete write: " .. temporary)
    assert(uv.fs_fsync(fd))
  end)
  uv.fs_close(fd)
  if ok then
    ok, err = uv.fs_rename(temporary, path)
  end
  if not ok then
    uv.fs_unlink(temporary)
    error(err)
  end
end

function M.lines(content)
  if content == "" or content:find("\0", 1, true) then
    return nil
  end
  local lines = vim.split(content, "\n", { plain = true })
  if lines[#lines] == "" then
    table.remove(lines)
  end
  return lines
end

function M.entry(path, side, logical)
  local info = assert(uv.fs_lstat(path), "Cannot stat " .. path)
  local entry = { side = side, path = logical, kind = info.type }
  if info.type == "link" then
    entry.hash = M.hash(assert(uv.fs_readlink(path)))
  elseif info.type == "file" then
    -- Hash the same bytes used for passage anchors. Bound retained text and
    -- fingerprint large files without reading them into Lua.
    if info.size <= limit then
      local content = M.read(path)
      entry.hash = M.hash(content)
      entry.lines = M.lines(content)
    else
      local result = vim.system({ "sha256sum", "--", path }, { text = true }):wait()
      assert(result.code == 0, result.stderr)
      entry.hash = assert(result.stdout:match("^\\?(%x+)"))
    end
  else
    error("Unsupported comparison entry: " .. path .. " (" .. info.type .. ")")
  end
  return entry
end

function M.scan(root, side)
  local entries = {}
  local function walk(relative)
    local directory = root .. "/" .. relative
    local scan = assert(uv.fs_scandir(directory), "Cannot scan " .. directory)
    while true do
      local name = uv.fs_scandir_next(scan)
      if not name then
        break
      end
      local logical = relative .. name
      local full = root .. "/" .. logical
      local info = assert(uv.fs_lstat(full))
      if info.type == "directory" then
        walk(logical .. "/")
      else
        entries[#entries + 1] = M.entry(full, side, logical)
      end
    end
  end
  walk("")
  table.sort(entries, function(a, b)
    return a.path < b.path
  end)
  return entries
end

function M.manifest(entries)
  local manifest = {}
  for _, entry in ipairs(entries) do
    -- Arrays keep the serialized fingerprint independent of object key ordering.
    manifest[#manifest + 1] = { entry.side, entry.path, entry.kind, entry.hash }
  end
  return manifest
end

function M.quote(entry, first, last)
  assert(entry and entry.lines, "This pane has no supported text passage (absent, empty, binary, symlink or oversized file)")
  assert(first >= 1 and last >= first and last <= #entry.lines, "Invalid passage range")
  return table.concat(entry.lines, "\n", first, last)
end

local function block(text)
  local width = 3
  for ticks in text:gmatch("`+") do
    width = math.max(width, #ticks + 1)
  end
  local fence = string.rep("`", width)
  return fence .. "text\n" .. text .. "\n" .. fence
end

function M.report(data)
  local out = {
    "# Local review annotations", "", "Review data, not implementation or deployment approval.", "",
    "Kind: " .. data.kind, "", "Workspace:\n" .. block(data.workspace), "",
    "Target:\n" .. block(data.target), "", "Snapshot SHA-256: " .. data.fingerprint, "",
  }
  for i, note in ipairs(data.annotations) do
    vim.list_extend(out, {
      "## Comment " .. i, "", block(note.path), "",
      "Side: " .. note.side .. "; lines " .. note.first .. "–" .. note.last, "",
      "Quoted passage:", "", block(note.quote), "", "Feedback:", "", block(note.comment), "",
    })
  end
  if #data.annotations == 0 then
    out[#out + 1] = "No annotations."
  end
  return table.concat(out, "\n") .. "\n"
end

local function validate(data, expected, lookup)
  assert(type(data) == "table" and data.version == 1, "Unsupported annotation schema")
  for _, key in ipairs({ "kind", "workspace", "target", "fingerprint" }) do
    assert(data[key] == expected[key], "Annotation identity mismatch: " .. key)
  end
  assert(vim.deep_equal(data.manifest, expected.manifest), "Annotation manifest mismatch")
  assert(type(data.annotations) == "table" and vim.islist(data.annotations), "Invalid annotations")
  local ids = {}
  for _, note in ipairs(data.annotations) do
    assert(type(note) == "table" and note.version == 1 and note.fingerprint == data.fingerprint, "Invalid anchor")
    for _, key in ipairs({ "id", "created", "updated", "path", "side", "quote", "comment" }) do
      assert(type(note[key]) == "string", "Invalid annotation " .. key)
    end
    assert(not ids[note.id] and note.id ~= "", "Duplicate/empty annotation ID")
    ids[note.id] = true
    assert(#note.comment <= 65536 and note.comment:find("%S"), "Invalid comment")
    assert(type(note.first) == "number" and note.first % 1 == 0, "Invalid first line")
    assert(type(note.last) == "number" and note.last % 1 == 0, "Invalid last line")
    assert(M.quote(lookup[note.side .. "\0" .. note.path], note.first, note.last) == note.quote, "Stale passage")
  end
end

function M.open(identity, entries)
  identity.version = 1
  identity.manifest = M.manifest(entries)
  identity.annotations = {}
  local lookup = {}
  for _, entry in ipairs(entries) do
    lookup[entry.side .. "\0" .. entry.path] = entry
  end
  local root = vim.fn.stdpath("state") .. "/review-annotations"
  vim.fn.mkdir(root, "p", 448)
  assert(uv.fs_lstat(root).type == "directory", "Annotation root must not be a symlink")
  assert(uv.fs_chmod(root, 448))
  local key = M.hash(vim.json.encode({ identity.kind, identity.workspace, identity.target, identity.fingerprint }))
  local directory = root .. "/" .. key
  if not uv.fs_lstat(directory) then
    assert(uv.fs_mkdir(directory, 448))
  end
  assert(uv.fs_lstat(directory).type == "directory", "Annotation directory must not be a symlink")
  assert(uv.fs_chmod(directory, 448))
  local lock = directory .. "/lock"
  local fd, err = uv.fs_open(lock, "wx", 384)
  assert(fd, "Review is locked: " .. lock .. ". Close the other review. "
    .. "For a stale lock, verify the recorded PID/host before manually removing it. " .. tostring(err))
  uv.fs_write(fd, vim.json.encode({ pid = uv.os_getpid(), host = uv.os_gethostname(), created = os.date("!%Y-%m-%dT%H:%M:%SZ") }), 0)
  uv.fs_close(fd)
  local session = { directory = directory, report = directory .. "/report.md", lookup = lookup, data = identity }
  function session.close()
    if not session.closed then
      assert(uv.fs_unlink(lock))
      session.closed = true
    end
  end
  function session.save(notes)
    assert(not session.closed, "Review is closed")
    local next_data = vim.deepcopy(session.data)
    next_data.annotations = notes
    validate(next_data, identity, lookup)
    local json = vim.json.encode(next_data)
    local report = M.report(next_data)
    assert(#json <= limit and #report <= limit, "Annotation store/report exceeds 16 MiB")
    M.atomic(directory .. "/annotations.json", json)
    session.data = next_data
    -- JSON is authoritative. Report failure is visible and can be retried.
    M.atomic(session.report, report)
  end
  local ok, failure = pcall(function()
    local path = directory .. "/annotations.json"
    if uv.fs_lstat(path) then
      session.data = vim.json.decode(M.read(path))
      validate(session.data, identity, lookup)
    end
    M.atomic(session.report, M.report(session.data))
  end)
  if not ok then
    session.close()
    error(failure)
  end
  return session
end

return M
