local N = {}

local notify = require("namespace.notify").notify
local api = vim.api

local cache = {
  composer_json = nil,
}

local sep = vim.uv.os_uname().sysname == "Windows_NT" and "\\" or "/"
local root = vim.fs.root(0, { ".git" }) or vim.uv.cwd()

local function is_drupal_project()
  local indicators = {
    "/web/core/composer.json",
    "/web/core/lib/Drupal.php",
  }

  for _, path in ipairs(indicators) do
    if vim.fn.filereadable(root .. path) == 1 then
      return true
    end
  end

  local composer_data = vim.json.decode(vim.fn.join(vim.fn.readfile(root .. "/composer.json"), "\n"))
  if composer_data and composer_data.require then
    for dep, _ in pairs(composer_data.require) do
      if dep:match("^drupal/") or dep == "drupal/core" then
        return true
      end
    end
  end

  return false
end

-- split to remove
local function parse(str)
  local psr = ""
  for match in str:gmatch("[a-zA-Z0-9]+") do
    psr = psr .. match:gsub("^.", string.upper) .. "\\"
  end
  return "namespace " .. psr:sub(1, -2) .. ";"
end

function N.resolve_namespace()
  if not is_drupal_project() then
    return N.resolve_namespace_composer()
  else
    return N.resolve_from_autoload_psr4()
  end
end

function N.resolve_namespace_composer()
  local composer_data = N.read_composer_file()
  if not composer_data then
    return nil
  end

  local prefix_and_src = N.get_prefix_and_src()

  local current_dir = vim.fn.expand("%:h")
  current_dir = current_dir:gsub(root, ""):gsub(sep, "\\")

  for _, entry in ipairs(prefix_and_src or {}) do
    if current_dir:find(entry.src) ~= nil then
      return parse(current_dir:gsub(entry.src, entry.prefix))
    end
  end
end

function N.resolve_from_autoload_psr4()
  local autoload_file = root .. "/vendor/composer/autoload_psr4.php"
  if vim.fn.filereadable(autoload_file) ~= 1 then
    return nil
  end

  local content = vim.fn.readfile(autoload_file)
  local psr4_map = {}

  for _, line in ipairs(content) do
    local prefix, path = line:match("['\"]([^'\"]+)['\"]%s*=>%s*array%(.-['\"]([^'\"]+)['\"]") -- double qoutes

    if prefix and path then
      path = path
      table.insert(psr4_map, {
        prefix = prefix,
        src = path,
      })
    end
  end

  local current_dir = vim.fn.expand("%:h")
  current_dir = sep .. current_dir:gsub(root, "")

  for _, entry in ipairs(psr4_map) do
    if current_dir:find(entry.src) ~= nil then
      return "namespace "
        .. current_dir:gsub(entry.src, entry.prefix):gsub("\\\\", "\\"):gsub("\\$", ""):gsub(sep, "")
        .. ";"
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
      table.insert(result, { prefix = prefix, src = src:gsub(sep .. "$", "") })
    end
  end

  if composer_data["autoload-dev"] ~= nil and composer_data["autoload-dev"]["psr-4"] ~= nil then
    for prefix, src in pairs(composer_data["autoload-dev"]["psr-4"]) do
      table.insert(result, { prefix = prefix, src = src:gsub(sep .. "$", "") })
    end
  end

  return result
end

function N.get_insertion_point()
  local content = api.nvim_buf_get_lines(0, 0, -1, false)
  if #content == 0 then
    return nil
  end

  local insertion_point = 2

  for i, line in ipairs(content) do
    if vim.fn.match(line, "^\\(declare\\)") >= 0 then
      insertion_point = i
    elseif vim.fn.match(line, "^\\(namespace\\)") >= 0 then
      return i, vim.fn.match(line, "^\\(namespace\\)")
    elseif vim.fn.match(line, "^\\(use\\)") >= 0 then
      return insertion_point, nil
    elseif vim.fn.match(line, "^\\(class\\|final\\|interface\\|abstract\\|trait\\|enum\\)") >= 0 then
      return insertion_point, nil
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
      notify("Namespace already exists")
    end
  end
end

return N
