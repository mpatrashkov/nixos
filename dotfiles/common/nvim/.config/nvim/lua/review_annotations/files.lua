local M = {}
local uv = vim.uv

M.limit = 16 * 1024 * 1024

function M.read(path)
  local info = assert(uv.fs_lstat(path), "Cannot stat " .. path)
  assert(info.type == "file" and info.size <= M.limit, "Expected a regular file <= 16 MiB: " .. path)

  local fd = assert(uv.fs_open(path, "r", 0))
  local content, err = uv.fs_read(fd, info.size, 0)
  uv.fs_close(fd)

  assert(content, err)
  assert(#content == info.size, "Incomplete read or file changed: " .. path)
  return content
end

function M.atomic(path, content)
  local temporary = path .. "." .. uv.os_getpid() .. "." .. uv.hrtime() .. ".tmp"
  local fd = assert(uv.fs_open(temporary, "wx", 384))

  local ok, err = pcall(function()
    assert(uv.fs_write(fd, content, 0) == #content, "Incomplete write: " .. path)
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

function M.private_directory(path)
  vim.fn.mkdir(path, "p", 448)

  local info = assert(uv.fs_lstat(path))
  assert(info.type == "directory", "Annotation directory must not be a symlink: " .. path)
  assert(uv.fs_chmod(path, 448))
end

function M.hash(content)
  -- Vim strings cannot reliably pass embedded NULs to sha256().
  local result = vim.system({ "sha256sum" }, { stdin = content, text = true }):wait()
  assert(result.code == 0, result.stderr)
  return assert(result.stdout:match("^(%x+)"))
end

function M.hash_file(path)
  local result = vim.system({ "sha256sum", "--", path }, { text = true }):wait()
  assert(result.code == 0, result.stderr)
  return assert(result.stdout:match("^\\?(%x+)"))
end

function M.lock(directory)
  local path = directory .. "/lock"
  local fd = uv.fs_open(path, "wx", 384)
  assert(fd, "Cannot lock review: " .. path
    .. ". Close the other review, or verify the recorded PID/host before removing a stale lock.")

  local owner = assert(uv.fs_fstat(fd))
  local content = vim.json.encode({
    pid = uv.os_getpid(), host = uv.os_gethostname(), created = os.date("!%Y-%m-%dT%H:%M:%SZ"),
  })

  local written, err = uv.fs_write(fd, content, 0)

  if written ~= #content then
    uv.fs_close(fd)
    uv.fs_unlink(path)
    error(err or "Incomplete lock write")
  end

  local released = false

  return function()
    if released then
      return
    end

    local ok, failure = pcall(function()
      local current = assert(uv.fs_lstat(path), "Review lock disappeared")
      assert(current.ino == owner.ino and current.dev == owner.dev, "Lock ownership changed; not removing it")
      assert(uv.fs_unlink(path))
    end)

    -- Keep the descriptor open until release so the owned inode cannot be reused.
    uv.fs_close(fd)
    released = true
    assert(ok, failure)
  end
end

return M
