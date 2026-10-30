local files = require("review_annotations.files")
local snapshot = require("review_annotations.snapshot")
local report = require("review_annotations.report")

local Store = {}
Store.__index = Store

local function entry_key(side, path)
  return side .. "\0" .. path
end

local function validate_note(note, data, lookup)
  assert(type(note) == "table" and note.version == 1, "Invalid annotation schema")
  assert(note.fingerprint == data.fingerprint, "Annotation fingerprint mismatch")

  for _, key in ipairs({ "id", "created", "updated", "path", "side", "quote", "comment" }) do
    assert(type(note[key]) == "string", "Invalid annotation field: " .. key)
    assert(snapshot.valid_utf8(note[key]), "Invalid annotation encoding: " .. key)
  end

  assert(note.id ~= "", "Empty annotation ID")
  assert(#note.comment <= 65536 and note.comment:find("%S"), "Comment must be nonempty and <= 64 KiB")
  assert(type(note.first) == "number" and note.first % 1 == 0, "Invalid first line")
  assert(type(note.last) == "number" and note.last % 1 == 0, "Invalid last line")

  local item = lookup[entry_key(note.side, note.path)]
  assert(snapshot.quote(item, note.first, note.last) == note.quote, "Stale passage")
end

local function validate(data, expected, lookup)
  assert(type(data) == "table" and data.version == 1, "Unsupported annotation schema")

  for _, key in ipairs({ "kind", "workspace", "target", "fingerprint" }) do
    assert(data[key] == expected[key], "Annotation identity mismatch: " .. key)
  end

  assert(vim.deep_equal(data.manifest, expected.manifest), "Annotation manifest mismatch")
  assert(type(data.annotations) == "table" and vim.islist(data.annotations), "Invalid annotations")

  local seen = {}

  for _, note in ipairs(data.annotations) do
    validate_note(note, data, lookup)
    assert(not seen[note.id], "Duplicate annotation ID")
    seen[note.id] = true
  end
end

local function load(self)
  local path = self.directory .. "/annotations.json"

  if vim.uv.fs_lstat(path) then
    local decoded, data = pcall(vim.json.decode, files.read(path))
    assert(decoded, "Corrupt annotation JSON; preserve the file and repair it explicitly")

    validate(data, self.expected, self.lookup)
    self.data = data
  end

  self:write_report()
end

function Store.open(identity, entries)
  identity.version = 1
  identity.workspace = assert(vim.uv.fs_realpath(identity.workspace))
  identity.manifest = snapshot.manifest(entries)
  identity.annotations = {}

  local root = vim.fn.stdpath("state") .. "/review-annotations"
  local key = files.hash(vim.json.encode({
    identity.kind, identity.workspace, identity.target, identity.fingerprint,
  }))
  local directory = root .. "/" .. key

  files.private_directory(root)
  files.private_directory(directory)

  local self = setmetatable({
    directory = directory,
    report = directory .. "/report.md",
    data = identity,
    expected = vim.deepcopy(identity),
    lookup = {},
    sequence = 0,
  }, Store)

  for _, item in ipairs(entries) do
    self.lookup[entry_key(item.side, item.path)] = item
  end

  self.release = files.lock(directory)
  local ok, err = pcall(load, self)

  if not ok then
    self:close()
    error(err)
  end

  return self
end

function Store:close()
  self.release()
  self.closed = true
end

function Store:write_report()
  assert(not self.closed, "Review is closed")
  local content = report.render(self.data)
  assert(#content <= files.limit, "Report exceeds 16 MiB")

  files.atomic(self.report, content)
  return content
end

function Store:save(notes)
  assert(not self.closed, "Review is closed")
  local data = vim.tbl_extend("force", self.data, { annotations = notes })
  validate(data, self.expected, self.lookup)

  local json = vim.json.encode(data)
  local markdown = report.render(data)
  assert(#json <= files.limit and #markdown <= files.limit, "Annotation store/report exceeds 16 MiB")

  files.atomic(self.directory .. "/annotations.json", json)
  self.data = data
  files.atomic(self.report, markdown)
end

function Store:entry(path, side)
  return self.lookup[entry_key(side, path)]
end

function Store:create(path, side, first, last)
  local passage = snapshot.quote(self:entry(path, side), first, last)
  local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
  self.sequence = self.sequence + 1

  return {
    version = 1,
    id = vim.uv.os_getpid() .. "-" .. vim.uv.hrtime() .. "-" .. self.sequence,
    fingerprint = self.data.fingerprint,
    created = timestamp,
    updated = timestamp,
    path = path,
    side = side,
    first = first,
    last = last,
    quote = passage,
    comment = "",
  }
end

function Store:put(note, comment, existing)
  local notes = vim.deepcopy(self.data.annotations)
  local saved = vim.deepcopy(note)
  saved.comment = comment
  saved.updated = os.date("!%Y-%m-%dT%H:%M:%SZ")

  for index, other in ipairs(notes) do
    if other.id == note.id then
      notes[index] = saved
      self:save(notes)
      return
    end
  end

  assert(not existing, "Annotation was removed")
  notes[#notes + 1] = saved
  self:save(notes)
end

function Store:remove(id)
  local notes = {}

  for _, note in ipairs(self.data.annotations) do
    if note.id ~= id then
      notes[#notes + 1] = note
    end
  end

  assert(#notes < #self.data.annotations, "Annotation was removed")
  self:save(notes)
end

function Store:at(path, side, row)
  local notes = {}

  for _, note in ipairs(self.data.annotations) do
    if note.path == path and note.side == side and note.first <= row and note.last >= row then
      notes[#notes + 1] = note
    end
  end

  return notes
end

function Store:finish()
  local content = self:write_report()

  return {
    version = 1,
    path = self.data.target,
    sha256 = self.data.fingerprint,
    report = self.report,
    reportSha256 = files.hash(content),
    count = #self.data.annotations,
  }
end

return Store
