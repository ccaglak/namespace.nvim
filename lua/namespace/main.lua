local ts, api, insert = vim.treesitter, vim.api, table.insert

local native = require("namespace.native")
local Queue = require("namespace.queue")
local com = require("namespace.composer")
local sort = require("namespace.sort")
local config = require("namespace").config
local vui = require("namespace.ui").select
local notify = require("namespace.notify").notify

if config.ui == false then
  vui = vim.ui.select
end

local cache = {
  root = nil,
  file_search_results = {},
  treesitter_queries = {},
  composer_prefix_src = nil,
}

local sep = vim.uv.os_uname().sysname == "Windows_NT" and "\\" or "/"

local function get_project_root()
  if cache.root ~= nil then
    return cache.root
  end
  cache.root = vim.fs.root(0, { "composer.json", ".git", "package.json", ".env" }) or vim.uv.cwd()
  return cache.root
end

local function get_current_file_directory()
  local current_file = vim.fn.expand("%:p")
  current_file = vim.fn.fnamemodify(current_file, ":h")
  return current_file:gsub(get_project_root(), "")
end

local function get_cached_query(language, query_string)
  local key = language .. query_string
  if not cache.treesitter_queries[key] then
    cache.treesitter_queries[key] = vim.treesitter.query.parse(language, query_string)
  end
  return cache.treesitter_queries[key]
end

-- Get classes from the current buffer using treesitter
local function get_classes_from_tree(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  local language_tree = ts.get_parser(bufnr, "php")
  if language_tree == nil then
    return
  end
  local syntax_tree = language_tree:parse()
  local root = syntax_tree[1]:root()

  local query = get_cached_query(
    "php",
    [[
        (attribute (name) @att)
        (scoped_call_expression scope:(name) @sce)
        (named_type (name) @named)
        (base_clause (name) @extends )
        (class_interface_clause (name) @implements)
        (class_constant_access_expression (name) @static (name))
        (simple_parameter type: (union_type (named_type (name) @name)))
        (object_creation_expression (name) @objcreation)
        (use_declaration (name) @use )
        (binary_expression operator: "instanceof" right: [ (name) @type (qualified_name (name) @type) ])
    ]]
  )

  -- (namespace_use_clause [ (name) @type (qualified_name (name) @type) ])
  local declarations = {}
  for _, node, _ in query:iter_captures(root, bufnr, 0, -1) do
    local name = ts.get_node_text(node, bufnr)
    table.insert(declarations, { name = name })
  end

  return declarations
end

-- Get namespaces from the current buffer
local function get_namespaces()
  local php_code = api.nvim_buf_get_lines(0, 0, 50, false)
  local use_statements = {}
  for _, line in ipairs(php_code) do
    if vim.fn.match(line, "^\\(class\\|final\\|interface\\|abstract\\|trait\\|enum\\)") > 0 then
      return use_statements
    end
    local use_match = line:match("^use%s+(.+);$")
    if use_match then
      local last_segment = use_match:match("([^\\]+)$")
      table.insert(use_statements, { name = last_segment, ns = use_match })
    end
  end
  return use_statements
end

-- Get filtered classes

local function get_filtered_classes()
  local function create_set(arr, key)
    local set = {}
    for _, item in ipairs(arr) do
      set[key and item[key] or item] = true
    end
    return set
  end
  local native_set = create_set(native)
  local all_classes = get_classes_from_tree()
  local namespace_set = create_set(get_namespaces(), "name")

  local usable_classes = {}
  local native_classes = {}
  local seen = {}

  for _, class in ipairs(all_classes or {}) do
    if not seen[class.name] then
      seen[class.name] = true
      if not namespace_set[class.name] then
        if native_set[class.name] then
          insert(native_classes, class)
        else
          insert(usable_classes, class)
        end
      end
    end
  end

  return usable_classes, native_classes
end

-- Transform file path to use statement ---
local function transform_path(path, prefix_table, workspace_root, composer)
  if not path then
    return nil
  end
  if composer then
    return "use " .. path:gsub("\\\\", "\\") .. ";"
  end

  path = path
    :gsub(workspace_root, "")
    :gsub("^" .. sep, "") -- remove first slash
    :gsub(sep, "\\") -- turn all separators backslashes
    :gsub("%.php$", "") -- remove .php

  local first_segment, rest = path:match("([^\\]+)\\(.*)")
  for _, prefix_entry in ipairs(prefix_table) do
    if first_segment == prefix_entry.src then
      return string.format("use %s%s;", prefix_entry.prefix, rest)
    end
  end
end

local function async_search_files(pattern, callback)
  if cache.file_search_results[pattern] then
    callback(cache.file_search_results[pattern])
    return
  end

  local rg_command = {
    "rg",
    "--files",
    "--glob",
    pattern,
    "--glob",
    "!vendor",
    "--glob",
    "!node_modules",
    "--glob",
    "!.git",
    --laravel specific
    "--glob",
    "!resources",
    "--glob",
    "!storage",
    "--glob",
    "!public",
    "--glob",
    "!database",
    "--glob",
    "!config",
    "--glob",
    "!bootstrap",
  }

  vim.system(rg_command, {}, function(obj)
    local results = {}
    if obj.code == 0 and obj.stdout then
      for file in obj.stdout:gmatch("[^\r\n]+") do
        table.insert(results, file)
      end
    end
    cache.file_search_results[pattern] = results
    vim.schedule(function()
      callback(results)
    end)
  end)
end

-- Search for classes in autoload_classmap.php
local function search_autoload_classmap(classes)
  local classmap_path = get_project_root() .. string.format("%svendor%scomposer%sautoload_classmap.php", sep, sep, sep)
  local results = {}

  for _, class in pairs(classes) do
    local rg_command = string.format("rg '%s' %s", sep .. class.name .. ".php", classmap_path)
    local output = vim.fn.system(rg_command)
    local file_paths = {}
    for line in output:gmatch("[^\r\n]+") do
      -- local fqcn, _, file_path = line:match("'([^']+)'%s*=>%s*%$(%w+Dir)%s*%.%s*'([^']+)'")
      local fqcn, file_path = line:match("'([^']+)'%s*=>%s*%$%w+Dir%s*%.%s*'([^']+)'")
      if fqcn and file_path then
        table.insert(file_paths, { fqcn = fqcn, path = file_path })
      end
    end
    results[class.name] = file_paths
  end
  return results
end

local function get_insertion_point()
  local content = api.nvim_buf_get_lines(0, 0, -1, false)
  if #content == 0 then
    return nil
  end
  local insertion_point = 2

  for i, line in ipairs(content) do
    if vim.fn.match(line, "^\\(declare\\|namespace\\|use\\)") >= 0 then
      insertion_point = i
    elseif vim.fn.match(line, "^\\(class\\|final\\|interface\\|abstract\\|trait\\|enum\\)") >= 0 then
      return insertion_point
    end
  end

  return insertion_point
end

local function process_classmap_results(paths, class_name, prefix, workspace_root, current_directory, callback)
  if #paths > 1 then
    vui(paths, {
      prompt = "Select the appropriate " .. class_name,
      format_item = function(item)
        return item.fqcn
      end,
    }, function(choice)
      if choice and vim.fn.fnamemodify(choice.path, ":h") ~= current_directory then
        local use_statement = transform_path(choice.fqcn, prefix, workspace_root, true)
        callback(use_statement)
      else
        callback(nil)
      end
    end)
  elseif #paths == 1 and vim.fn.fnamemodify(paths[1].path, ":h") ~= current_directory then
    local use_statement = transform_path(paths[1].fqcn, prefix, workspace_root, true)
    callback(use_statement)
  else
    return false
  end
  return true
end

local function process_file_search(class_entry, prefix, workspace_root, current_directory, callback)
  async_search_files(class_entry.name .. ".php", function(files)
    local matching_files

    if files and #files == 1 then
      matching_files = vim.tbl_filter(function(file)
        return file:match(class_entry.name:gsub("\\", "/") .. ".php$")
          and vim.fn.fnamemodify(file, ":h") ~= current_directory:sub(2)
      end, files)
    else
      matching_files = files
    end

    matching_files = vim.tbl_map(function(file)
      return transform_path(file, prefix, workspace_root)
    end, matching_files)

    if #matching_files == 1 then
      callback(matching_files[1])
    elseif #matching_files > 1 then
      vui(matching_files, {
        prompt = "Select the appropriate " .. class_entry.name,
        format_item = function(item)
          return item
        end,
      }, callback)
    else
      notify("No matches found for " .. class_entry.name)
      callback(nil)
    end
  end)
end

local function process_single_class(class_entry, prefix, workspace_root, current_directory, callback)
  process_file_search(class_entry, prefix, workspace_root, current_directory, function(result)
    if result then
      callback(result)
    else
      local classmap_results = search_autoload_classmap({ class_entry })
      if classmap_results[class_entry.name] then
        local paths = classmap_results[class_entry.name]
        if type(paths) == "table" then
          process_classmap_results(paths, class_entry.name, prefix, workspace_root, current_directory, callback)
        else
          callback(nil)
        end
      else
        callback(nil)
      end
    end
  end)
end

local function process_class_queue(queue, prefix, workspace_root, current_directory, callback)
  local use_statements = {}

  local function process_next()
    if queue:is_empty() then
      callback(use_statements)
      return
    end

    local class_entry = queue:pop()
    process_single_class(class_entry, prefix, workspace_root, current_directory, function(use_statement)
      if use_statement then
        table.insert(use_statements, use_statement)
      end
      process_next()
    end)
  end

  process_next()
end

local function get_prefix_and_src()
  if not cache.composer_prefix_src then
    cache.composer_prefix_src = com.get_prefix_and_src()
  end
  return cache.composer_prefix_src
end

local function has_composer_json()
  local composer_json_path = get_project_root() .. "/composer.json"
  return vim.fn.filereadable(composer_json_path) == 1
end

local M = {}

function M.getClass()
  if not has_composer_json() then
    notify("composer.json not found ")
    return
  end

  local word_under_cursor = vim.fn.expand("<cword>")
  if word_under_cursor == "" then
    notify("No word under cursor")
    return
  end

  local existing_namespaces = get_namespaces()
  for _, ns in ipairs(existing_namespaces) do
    if ns.name == word_under_cursor then
      notify("Class '" .. word_under_cursor .. "' is already used")
      return
    end
  end

  local insertion_point = get_insertion_point()
  local prefix = get_prefix_and_src()
  local current_directory = get_current_file_directory()
  local workspace_root = get_project_root()
  local lines_to_insert = {}

  if vim.tbl_contains(native, word_under_cursor) then
    local use_statement = "use " .. word_under_cursor .. ";"
    api.nvim_buf_set_lines(0, insertion_point, insertion_point, false, { use_statement })
    notify("Added native class: " .. word_under_cursor)
    return
  end

  local filtered_classes = { { name = word_under_cursor } }

  if #filtered_classes == 0 then
    notify("No class found under cursor")
    return
  end

  local class_queue = Queue.new()
  for _, class_entry in ipairs(filtered_classes) do
    class_queue:push(class_entry)
  end

  process_class_queue(class_queue, prefix, workspace_root, current_directory, function(use_statements)
    vim.list_extend(lines_to_insert, use_statements)
    api.nvim_buf_set_lines(0, insertion_point, insertion_point, false, lines_to_insert)
    if config.sort.on_save then
      sort.sortUseStatements(config.sort)
    end
  end)
end

function M.getClasses()
  if not has_composer_json() then
    notify("composer.json not found ")
    return
  end

  local filtered_classes, native_classes = get_filtered_classes()
  if not filtered_classes then
    notify("No classes found to process")
    return
  end

  local insertion_point = get_insertion_point()
  local prefix = get_prefix_and_src()
  local workspace_root = get_project_root()
  local lines_to_insert = {}
  local current_directory = get_current_file_directory()

  -- Process native classes
  for _, native_class in ipairs(native_classes) do
    table.insert(lines_to_insert, "use " .. native_class.name .. ";")
  end

  -- Create a queue for processing filtered classes
  local class_queue = Queue.new()
  for _, class_entry in ipairs(filtered_classes) do
    class_queue:push(class_entry)
  end

  process_class_queue(class_queue, prefix, workspace_root, current_directory, function(use_statements)
    vim.list_extend(lines_to_insert, use_statements)
    api.nvim_buf_set_lines(0, insertion_point, insertion_point, false, lines_to_insert)

    if config.sort.on_save then
      sort.sortUseStatements(config.sort)
    end
  end)
end

return M
