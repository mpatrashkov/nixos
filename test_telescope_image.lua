local function setup_telescope_image()
  local ok, telescope = pcall(require, "telescope")
  if not ok then return end

  local previewers = require("telescope.previewers")
  local image_api = require("image")

  local image_preview_maker = function(filepath, bufnr, opts)
    filepath = vim.fn.expand(filepath)
    local is_image = filepath:match("%.png$") or filepath:match("%.jpg$") or filepath:match("%.jpeg$") or filepath:match("%.gif$") or filepath:match("%.webp$")
    if is_image then
      local winid = vim.fn.bufwinid(bufnr)
      if winid ~= -1 then
        local img = image_api.from_file(filepath, {
          window = winid,
          buffer = bufnr,
        })
        if img then
          img:render()
        end
      end
      return
    end
    require("telescope.previewers").buffer_previewer_maker(filepath, bufnr, opts)
  end

  -- We would set this in telescope defaults
end
