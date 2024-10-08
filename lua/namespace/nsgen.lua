local N = {}

local api = vim.api

local cache = {
  composer_json = nil,
}

local sep = vim.uv.os_uname().sysname == "Windows_NT" and "\\" or "/"
local root = vim.fs.root(0, { "composer.json", ".git", "vendor" })

-- split to remove
local function parse(str)
  local psr = ""
  for match in str:gmatch("[a-zA-Z0-9]+") do
    psr = psr .. match:gsub("^.", string.upper) .. "\\"
  end
  return "namespace " .. psr:sub(1, -2) .. ";"
end

function N.resolve_namespace()
  local composer_data = N.read_composer_file()
  if not composer_data then
    return nil
  end

  local prefix_and_src = N.get_prefix_and_src()
  local current_dir = vim.fn.expand("%:h")
  current_dir = current_dir:gsub(root, ""):gsub(sep, "\\")

  -- P(current_dir)

  for _, entry in ipairs(prefix_and_src or {}) do
    if current_dir:find(entry.src:sub(1, -1)) ~= nil then
      return parse(current_dir:gsub(entry.src, entry.prefix))
    end
  end
end

function N.read_composer_file()
  if cache.composer_json then
    return cache.composer_json
  end

  local filename = vim.fn.findfile("composer.json", ".;")
  if filename == "" then
    return
  end
  local content = vim.fn.readfile(filename)

  cache.composer_json = vim.json.decode(table.concat(content, "\n"))
  return cache.composer_json
end

-- Get prefix and src from composer.json
function N.get_prefix_and_src()
  local composer_data = N.read_composer_file()

  if composer_data == nil or composer_data["autoload"] == nil then
    return nil, nil
  end

  local autoload = composer_data["autoload"]
  local result = {}

  if autoload["psr-4"] ~= nil then
    for prefix, src in pairs(autoload["psr-4"]) do
      table.insert(result, { prefix = prefix, src = src })
    end
  end

  if composer_data["autoload-dev"] ~= nil and composer_data["autoload-dev"]["psr-4"] ~= nil then
    for prefix, src in pairs(composer_data["autoload-dev"]["psr-4"]) do
      table.insert(result, { prefix = prefix, src = src })
    end
  end

  return result
end

function N.get_insertion_point()
  local content = api.nvim_buf_get_lines(0, 0, -1, false)
  local insertion_point = 2

  for i, line in ipairs(content) do
    if vim.fn.match(line, "^\\(declare\\)") >= 0 then
      insertion_point = i
    elseif vim.fn.match(line, "^\\(namespace\\)") >= 0 then
      return i, vim.fn.match(line, "^\\(namespace\\)")
    elseif vim.fn.match(line, "^\\(use\\|class\\|final\\|interface\\|abstract\\|trait\\|enum\\)") >= 0 then
      return insertion_point
    end
  end

  return insertion_point, nil
end

function N.resolve()
  local ns = N.resolve_namespace()
  if ns then
    local insertion, ok = N.get_insertion_point()
    if not ok then
      api.nvim_buf_set_lines(0, insertion, insertion, false, { ns })
    else
      vim.notify("Namespace already exists", "", "warn")
    end
  end
end

return N
