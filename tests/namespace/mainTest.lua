local ts, api, insert = vim.treesitter, vim.api, table.insert

local native = require("namespace.native")
local Queue = require("namespace.queue")
local com = require("namespace.composer")
local sort = require("namespace.sort")
local config = require("namespace").config
local vus = require("namespace.ui").select
local notify = require("namespace.notify").notify
local M = {}
if config.ui == false then
  vus = vim.ui.select
end

local cache = {
  root = nil,
  file_search_results = {},
  treesitter_queries = {},
  composer_prefix_src = nil,
}

local sep = vim.uv.os_uname().sysname == "Windows_NT" and "\\" or "/"

function M.get_project_root()
  if cache.root ~= nil then
    return cache.root
  end
  cache.root = vim.fs.root(0, { "composer.json", ".git", ".env" }) or vim.uv.cwd()
  return cache.root
end

function M.get_current_file_directory()
  local current_file = vim.fn.expand("%:p")
  current_file = vim.fn.fnamemodify(current_file, ":h")
  return current_file:gsub(M.get_project_root(), "")
end

function M.get_cached_query(language, query_string)
  local key = language .. query_string
  if not cache.treesitter_queries[key] then
    cache.treesitter_queries[key] = vim.treesitter.query.parse(language, query_string)
  end
  return cache.treesitter_queries[key]
end

-- Get classes from the current buffer using treesitter
function M.get_classes_from_tree(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  local language_tree = ts.get_parser(bufnr, "php")
  if language_tree == nil then
    return
  end
  local syntax_tree = language_tree:parse()
  local root = syntax_tree[1]:root()

  local query = M.get_cached_query(
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
function M.get_namespaces()
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

function M.get_filtered_classes()
  local function create_set(arr, key)
    local set = {}
    for _, item in ipairs(arr) do
      set[key and item[key] or item] = true
    end
    return set
  end
  local native_set = create_set(native)
  local all_classes = M.get_classes_from_tree()
  local namespace_set = create_set(M.get_namespaces(), "name")

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
function M.transform_path(path, prefix_table, workspace_root, composer)
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

function M.async_search_files(pattern, callback)
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
function M.search_autoload_classmap(classes)
  local classmap_path = M.get_project_root()
    .. string.format("%svendor%scomposer%sautoload_classmap.php", sep, sep, sep)
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

function M.get_insertion_point()
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

function M.table_unique(tbl)
  return vim.fn.uniq(vim.fn.sort(vim.fn.copy(tbl)))
end

function M.process_single_class(class_entry, prefix, workspace_root, current_directory, callback)
  local all_results = {}
  local same_path = false
  local file_path, transform_input
  local function process_paths(paths, is_composer)
    for _, path in ipairs(paths) do
      file_path = is_composer and path.path or path
      transform_input = is_composer and path.fqcn or file_path
      local dir = vim.fn.fnamemodify(file_path, ":h"):gsub("^" .. sep, "")
      current_directory = current_directory:gsub("^" .. sep, "")
      if #paths == 1 and dir ~= current_directory then
        table.insert(all_results, M.transform_path(transform_input, prefix, workspace_root, is_composer))
      elseif #paths > 1 then
        if dir == current_directory then
          same_path = true
        end
        table.insert(all_results, M.transform_path(transform_input, prefix, workspace_root, is_composer))
      end
    end
  end

  local classmap_results = M.search_autoload_classmap({ class_entry })
  if classmap_results[class_entry.name] then
    process_paths(classmap_results[class_entry.name], true)
  end

  M.async_search_files(class_entry.name .. ".php", function(files)
    process_paths(files, false)
    all_results = M.table_unique(all_results)

    if #all_results == 1 then
      callback(all_results[1])
    elseif #all_results > 1 then
      M.vim_ui_select(all_results, {
        prompt = string.format("Select the appropriate (%s%s)", same_path and "*** " or "", class_entry.name),
        format_item = function(item)
          return item
        end,
      }, function(choice)
        if same_path and M.transform_path(transform_input, prefix, workspace_root, false) == choice then
          callback(nil)
        else
          callback(choice)
        end
      end)
    else
      notify("No matches found for " .. class_entry.name)
      callback(nil)
    end
  end)
end

function M.process_class_queue(queue, prefix, workspace_root, current_directory, callback)
  local use_statements = {}

  local function process_next()
    if queue:is_empty() then
      callback(use_statements)
      return
    end

    local class_entry = queue:pop()
    M.process_single_class(class_entry, prefix, workspace_root, current_directory, function(use_statement)
      if use_statement then
        table.insert(use_statements, use_statement)
      end
      process_next()
    end)
  end

  process_next()
end

function M.get_prefix_and_src()
  if not cache.composer_prefix_src then
    cache.composer_prefix_src = com.get_prefix_and_src()
  end
  return cache.composer_prefix_src
end

function M.has_composer_json()
  local composer_json_path = M.get_project_root() .. "/composer.json"
  return vim.fn.filereadable(composer_json_path) == 1
end

function M.getClass()
  if not M.has_composer_json() then
    notify("composer.json not found ")
    return
  end

  local word_under_cursor = vim.fn.expand("<cword>")
  if word_under_cursor == "" then
    notify("No word under cursor")
    return
  end

  local existing_namespaces = M.get_namespaces()
  for _, ns in ipairs(existing_namespaces) do
    if ns.name == word_under_cursor then
      notify("Class '" .. word_under_cursor .. "' is already used")
      return
    end
  end

  local insertion_point = M.get_insertion_point()
  local prefix = M.get_prefix_and_src()
  local current_directory = M.get_current_file_directory()
  local workspace_root = M.get_project_root()
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

  M.process_class_queue(class_queue, prefix, workspace_root, current_directory, function(use_statements)
    vim.list_extend(lines_to_insert, use_statements)
    api.nvim_buf_set_lines(0, insertion_point, insertion_point, false, lines_to_insert)
    if config.sort.on_save then
      sort.sortUseStatements(config.sort)
    end
  end)
end

function M.getClasses()
  if not M.has_composer_json() then
    notify("composer.json not found ")
    return
  end

  local filtered_classes, native_classes = M.get_filtered_classes()
  if not filtered_classes then
    notify("No classes found to process")
    return
  end

  local insertion_point = M.get_insertion_point()
  local prefix = M.get_prefix_and_src()
  local workspace_root = M.get_project_root()
  local lines_to_insert = {}
  local current_directory = M.get_current_file_directory()

  -- Process native classes
  for _, native_class in ipairs(native_classes) do
    table.insert(lines_to_insert, "use " .. native_class.name .. ";")
  end

  -- Create a queue for processing filtered classes
  local class_queue = Queue.new()
  for _, class_entry in ipairs(filtered_classes) do
    class_queue:push(class_entry)
  end

  M.process_class_queue(class_queue, prefix, workspace_root, current_directory, function(use_statements)
    vim.list_extend(lines_to_insert, use_statements)
    api.nvim_buf_set_lines(0, insertion_point, insertion_point, false, lines_to_insert)

    if config.sort.on_save then
      sort.sortUseStatements(config.sort)
    end
  end)
end

return M
