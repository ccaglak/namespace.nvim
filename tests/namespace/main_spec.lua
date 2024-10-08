local M = require("namespace.main_test")

local mock = require("luassert.mock")
local stub = require("luassert.stub")

_G.dd = function(v)
  print(vim.inspect(v))
  return v
end

describe("Project root and file directory functions", function()
  it("should get project root", function()
    local mock_root = "/path/to/project"
    stub(vim.fs, "root").returns(mock_root)

    local result = M.get_project_root()

    assert.equals(mock_root, result)
    assert.stub(vim.fs.root).was_called_with(0, { "composer.json", ".git", "vendor" })

    vim.fs.root:revert()
  end)

  it("should get current file directory", function()
    local mock_project_root = "/path/to/project"
    local mock_current_file = "/path/to/project/src/file.php"

    stub(vim.fn, "expand").returns(mock_current_file)
    stub(vim.fn, "fnamemodify").returns(mock_current_file)
    stub(M, "get_project_root").returns(mock_project_root)

    assert.stub(vim.fn.expand).was_called_with("%:p")
    assert.stub(vim.fn.fnamemodify).was_called_with(mock_current_file, ":h")
    assert.stub(M.get_project_root).was_called()

    local result = M.get_current_file_directory()

    assert.equals("/src", result)

    vim.fn.expand:revert()
    vim.fn.fnamemodify:revert()
    M.get_project_root:revert()
  end)

  it("should handle root directory as current file", function()
    local mock_project_root = "/path/to/project"

    stub(vim.fn, "expand").returns(mock_project_root)
    stub(vim.fn, "fnamemodify").returns(mock_project_root)
    stub(M, "get_project_root").returns(mock_project_root)

    local result = M.get_current_file_directory()

    assert.equals("", result)

    vim.fn.expand:revert()
    vim.fn.fnamemodify:revert()
    M.get_project_root:revert()
  end)
end)
describe("get_classes_from_tree function", function()
  local mock_bufnr = 1
  local mock_root = {}
  local mock_query = {
    iter_captures = function() end,
  }

  before_each(function()
    stub(api, "nvim_get_current_buf").returns(mock_bufnr)
    stub(ts, "get_parser").returns({
      parse = function()
        return {
          {
            root = function()
              return mock_root
            end,
          },
        }
      end,
    })
    stub(M, "get_cached_query").returns(mock_query)
    stub(ts, "get_node_text")
  end)

  after_each(function()
    api.nvim_get_current_buf:revert()
    ts.get_parser:revert()
    M.get_cached_query:revert()
    ts.get_node_text:revert()
  end)

  it("should return nil if language_tree is nil", function()
    ts.get_parser.returns(nil)
    local result = M.get_classes_from_tree()
    assert.is_nil(result)
  end)

  it("should use the provided bufnr", function()
    local custom_bufnr = 2
    M.get_classes_from_tree(custom_bufnr)
    assert.stub(ts.get_parser).was_called_with(custom_bufnr, "php")
  end)

  it("should use the current buffer if no bufnr is provided", function()
    M.get_classes_from_tree()
    assert.stub(api.nvim_get_current_buf).was_called()
    assert.stub(ts.get_parser).was_called_with(mock_bufnr, "php")
  end)

  it("should return declarations from query captures", function()
    local mock_captures = {
      { name = "TestClass" },
      { name = "AnotherClass" },
    }
    stub(mock_query, "iter_captures").returns(coroutine.wrap(function()
      for _, capture in ipairs(mock_captures) do
        coroutine.yield(nil, {}, capture.name)
      end
    end))
    ts.get_node_text.on_call_with({}, mock_bufnr).returns("TestClass").returns("AnotherClass")

    local result = M.get_classes_from_tree()

    assert.same({
      { name = "TestClass" },
      { name = "AnotherClass" },
    }, result)
  end)

  it("should handle empty query results", function()
    stub(mock_query, "iter_captures").returns(coroutine.wrap(function() end))

    local result = M.get_classes_from_tree()

    assert.same({}, result)
  end)
end)
describe("get_namespaces function", function()
  local mock_buf_lines

  before_each(function()
    mock_buf_lines = {}
    stub(api, "nvim_buf_get_lines").returns(mock_buf_lines)
    stub(vim.fn, "match")
  end)

  after_each(function()
    api.nvim_buf_get_lines:revert()
    vim.fn.match:revert()
  end)

  it("should return empty table when no use statements are found", function()
    mock_buf_lines = {
      "<?php",
      "",
      "namespace App\\Controllers;",
      "",
      "class UserController",
      "{",
      "    // Some code",
      "}",
    }

    local result = M.get_namespaces()
    assert.same({}, result)
  end)

  it("should return use statements until class declaration", function()
    mock_buf_lines = {
      "<?php",
      "",
      "namespace App\\Controllers;",
      "",
      "use App\\Models\\User;",
      "use App\\Services\\AuthService;",
      "",
      "class UserController",
      "{",
      "    // Some code",
      "}",
    }

    vim.fn.match
      .on_call_with("class UserController", "^\\(class\\|final\\|interface\\|abstract\\|trait\\|enum\\)")
      .returns(0)

    local result = M.get_namespaces()
    assert.same({
      { name = "User", ns = "App\\Models\\User" },
      { name = "AuthService", ns = "App\\Services\\AuthService" },
    }, result)
  end)

  it("should handle multiple use statements on a single line", function()
    mock_buf_lines = {
      "<?php",
      "",
      "namespace App\\Controllers;",
      "",
      "use App\\Models\\{User, Post};",
      "use App\\Services\\AuthService;",
      "",
      "class UserController",
      "{",
      "    // Some code",
      "}",
    }

    vim.fn.match
      .on_call_with("class UserController", "^\\(class\\|final\\|interface\\|abstract\\|trait\\|enum\\)")
      .returns(0)

    local result = M.get_namespaces()
    assert.same({
      { name = "Post", ns = "App\\Models\\{User, Post}" },
      { name = "AuthService", ns = "App\\Services\\AuthService" },
    }, result)
  end)

  it("should handle use statements with aliases", function()
    mock_buf_lines = {
      "<?php",
      "",
      "namespace App\\Controllers;",
      "",
      "use App\\Models\\User as UserModel;",
      "use App\\Services\\AuthService;",
      "",
      "class UserController",
      "{",
      "    // Some code",
      "}",
    }

    vim.fn.match
      .on_call_with("class UserController", "^\\(class\\|final\\|interface\\|abstract\\|trait\\|enum\\)")
      .returns(0)

    local result = M.get_namespaces()
    assert.same({
      { name = "UserModel", ns = "App\\Models\\User as UserModel" },
      { name = "AuthService", ns = "App\\Services\\AuthService" },
    }, result)
  end)

  it("should stop parsing at the first class-like declaration", function()
    mock_buf_lines = {
      "<?php",
      "",
      "namespace App\\Controllers;",
      "",
      "use App\\Models\\User;",
      "use App\\Services\\AuthService;",
      "",
      "final class UserController",
      "{",
      "    // Some code",
      "}",
      "",
      "use App\\Helpers\\StringHelper;",
    }

    vim.fn.match
      .on_call_with("final class UserController", "^\\(class\\|final\\|interface\\|abstract\\|trait\\|enum\\)")
      .returns(0)

    local result = M.get_namespaces()
    assert.same({
      { name = "User", ns = "App\\Models\\User" },
      { name = "AuthService", ns = "App\\Services\\AuthService" },
    }, result)
  end)

  it("should handle empty lines and comments between use statements", function()
    mock_buf_lines = {
      "<?php",
      "",
      "namespace App\\Controllers;",
      "",
      "use App\\Models\\User;",
      "",
      "// Authentication service",
      "use App\\Services\\AuthService;",
      "",
      "class UserController",
      "{",
      "    // Some code",
      "}",
    }

    vim.fn.match
      .on_call_with("class UserController", "^\\(class\\|final\\|interface\\|abstract\\|trait\\|enum\\)")
      .returns(0)

    local result = M.get_namespaces()
    assert.same({
      { name = "User", ns = "App\\Models\\User" },
      { name = "AuthService", ns = "App\\Services\\AuthService" },
    }, result)
  end)
end)
describe("get_filtered_classes function", function()
  local mock_all_classes
  local mock_namespace_classes
  local mock_native_classes

  before_each(function()
    mock_all_classes = {
      { name = "TestClass" },
      { name = "NativeClass" },
      { name = "AnotherClass" },
      { name = "NamespaceClass" },
    }
    mock_namespace_classes = {
      { name = "NamespaceClass", ns = "App\\NamespaceClass" },
    }
    mock_native_classes = { "NativeClass" }

    stub(table, "remove_duplicates").returns(mock_all_classes)
    stub(M, "get_classes_from_tree").returns(mock_all_classes)
    stub(M, "get_namespaces").returns(mock_namespace_classes)
    stub(table, "contains2").returns(false)
    stub(vim, "tbl_contains").returns(false)
    _G.native = mock_native_classes
  end)

  after_each(function()
    table.remove_duplicates:revert()
    M.get_classes_from_tree:revert()
    M.get_namespaces:revert()
    table.contains2:revert()
    vim.tbl_contains:revert()
  end)

  it("should filter out namespace classes", function()
    table.contains2.on_call_with(mock_namespace_classes, "NamespaceClass").returns(true)

    local filtered, native = M.get_filtered_classes()

    assert.same({
      { name = "TestClass" },
      { name = "NativeClass" },
      { name = "AnotherClass" },
    }, filtered)
    assert.same({}, native)
  end)

  it("should separate native classes", function()
    vim.tbl_contains.on_call_with(mock_native_classes, "NativeClass").returns(true)

    local filtered, native = M.get_filtered_classes()

    assert.same({
      { name = "TestClass" },
      { name = "AnotherClass" },
    }, filtered)
    assert.same({
      { name = "NativeClass" },
    }, native)
  end)

  it("should handle empty input", function()
    table.remove_duplicates.returns({})
    M.get_classes_from_tree.returns({})

    local filtered, native = M.get_filtered_classes()

    assert.same({}, filtered)
    assert.same({}, native)
  end)

  it("should handle all classes being namespace classes", function()
    table.contains2.returns(true)

    local filtered, native = M.get_filtered_classes()

    assert.same({}, filtered)
    assert.same({}, native)
  end)

  it("should handle all classes being native classes", function()
    vim.tbl_contains.returns(true)

    local filtered, native = M.get_filtered_classes()

    assert.same({}, filtered)
    assert.same(mock_all_classes, native)
  end)
end)

describe("transform_path function", function()
  local mock_workspace_root = "/path/to/workspace"
  local mock_prefix_table = {
    { src = "src", prefix = "App\\" },
    { src = "tests", prefix = "Tests\\" },
  }

  it("should return nil for nil input", function()
    local result = M.transform_path(nil, mock_prefix_table, mock_workspace_root, false)
    assert.is_nil(result)
  end)

  it("should transform path without composer", function()
    local input_path = "/path/to/workspace/src/Controllers/UserController.php"
    local expected_output = "use App\\Controllers\\UserController;"

    local result = M.transform_path(input_path, mock_prefix_table, mock_workspace_root, false)
    assert.equals(expected_output, result)
  end)

  it("should transform path with composer", function()
    local input_path = "/path/to/workspace/vendor/package/src/SomeClass.php"
    local expected_output = "use App\\SomeClass;"

    local result = M.transform_path(input_path, mock_prefix_table, mock_workspace_root, true)
    assert.equals(expected_output, result)
  end)

  it("should handle paths with multiple backslashes", function()
    local input_path = "/path/to/workspace\\src\\Models\\User.php"
    local expected_output = "use App\\Models\\User;"

    local result = M.transform_path(input_path, mock_prefix_table, mock_workspace_root, false)
    assert.equals(expected_output, result)
  end)

  it("should handle paths without matching prefix", function()
    local input_path = "/path/to/workspace/lib/Helpers/StringHelper.php"
    local expected_output = "use lib\\Helpers\\StringHelper;"

    local result = M.transform_path(input_path, mock_prefix_table, mock_workspace_root, false)
    assert.equals(expected_output, result)
  end)

  it("should handle paths with different separators", function()
    local input_path = "/path/to/workspace/tests/Unit/UserTest.php"
    local expected_output = "use Tests\\Unit\\UserTest;"

    local result = M.transform_path(input_path, mock_prefix_table, mock_workspace_root, false)
    assert.equals(expected_output, result)
  end)
end)
describe("async_search_files function", function()
  local mock_callback
  local mock_vim_system

  before_each(function()
    mock_callback = spy.new(function() end)
    mock_vim_system = stub(vim, "system")
    _G.cache = { file_search_results = {} }
  end)

  after_each(function()
    mock_vim_system:revert()
  end)

  it("should return cached results if available", function()
    local pattern = "*.php"
    local cached_results = { "file1.php", "file2.php" }
    cache.file_search_results[pattern] = cached_results

    M.async_search_files(pattern, mock_callback)

    assert.spy(mock_callback).was_called_with(cached_results)
    assert.stub(mock_vim_system).was_not_called()
  end)

  it("should execute rg command with correct parameters", function()
    local pattern = "*.js"
    local expected_command = {
      "rg",
      "--files",
      "--glob",
      "*.js",
      "--glob",
      "!vendor",
      "--glob",
      "!node_modules",
      "--glob",
      "!.git",
    }

    M.async_search_files(pattern, mock_callback)

    assert.stub(mock_vim_system).was_called_with(expected_command, {}, match.is_function())
  end)

  it("should handle empty search results", function()
    local pattern = "*.nonexistent"
    mock_vim_system.invokes(function(_, _, callback)
      callback({ code = 0, stdout = "" })
    end)

    M.async_search_files(pattern, mock_callback)

    assert.spy(mock_callback).was_called_with({})
    assert.equals({}, cache.file_search_results[pattern])
  end)

  it("should handle search failure", function()
    local pattern = "*.fail"
    mock_vim_system.invokes(function(_, _, callback)
      callback({ code = 1, stdout = nil })
    end)

    M.async_search_files(pattern, mock_callback)

    assert.spy(mock_callback).was_called_with({})
    assert.equals({}, cache.file_search_results[pattern])
  end)

  it("should process multiple search results", function()
    local pattern = "*.txt"
    local mock_stdout = "file1.txt\nfile2.txt\nfile3.txt"
    mock_vim_system.invokes(function(_, _, callback)
      callback({ code = 0, stdout = mock_stdout })
    end)

    M.async_search_files(pattern, mock_callback)

    assert.spy(mock_callback).was_called_with({ "file1.txt", "file2.txt", "file3.txt" })
    assert.same({ "file1.txt", "file2.txt", "file3.txt" }, cache.file_search_results[pattern])
  end)

  it("should handle results with different line endings", function()
    local pattern = "*.mixed"
    local mock_stdout = "file1.mixed\r\nfile2.mixed\nfile3.mixed\r\n"
    mock_vim_system.invokes(function(_, _, callback)
      callback({ code = 0, stdout = mock_stdout })
    end)

    M.async_search_files(pattern, mock_callback)

    assert.spy(mock_callback).was_called_with({ "file1.mixed", "file2.mixed", "file3.mixed" })
    assert.same({ "file1.mixed", "file2.mixed", "file3.mixed" }, cache.file_search_results[pattern])
  end)
end)
describe("search_autoload_classmap function", function()
  local mock_root = "/path/to/project"
  local mock_sep = "/"

  before_each(function()
    _G.root = mock_root
    _G.sep = mock_sep
    stub(vim.fn, "system")
  end)

  after_each(function()
    vim.fn.system:revert()
  end)

  it("should return empty results for empty input", function()
    local result = M.search_autoload_classmap({})
    assert.same({}, result)
  end)

  it("should handle single class search", function()
    local mock_output = "'App\\Models\\User' => $baseDir . '/src/Models/User.php'"
    vim.fn.system.returns(mock_output)

    local result = M.search_autoload_classmap({ { name = "User" } })

    assert.same({
      User = {
        { fqcn = "App\\Models\\User", path = "/src/Models/User.php" },
      },
    }, result)
  end)

  it("should handle multiple classes search", function()
    local mock_outputs = {
      "'App\\Models\\User' => $baseDir . '/src/Models/User.php'",
      "'App\\Controllers\\HomeController' => $baseDir . '/src/Controllers/HomeController.php'",
    }
    vim.fn.system.on_call_with(match.is_string()).returns(mock_outputs[1]).returns(mock_outputs[2])

    local result = M.search_autoload_classmap({ { name = "User" }, { name = "HomeController" } })

    assert.same({
      User = {
        { fqcn = "App\\Models\\User", path = "/src/Models/User.php" },
      },
      HomeController = {
        { fqcn = "App\\Controllers\\HomeController", path = "/src/Controllers/HomeController.php" },
      },
    }, result)
  end)

  it("should handle classes with multiple matches", function()
    local mock_output =
      "'App\\Models\\User' => $baseDir . '/src/Models/User.php'\n'App\\Legacy\\User' => $baseDir . '/legacy/User.php'"
    vim.fn.system.returns(mock_output)

    local result = M.search_autoload_classmap({ { name = "User" } })

    assert.same({
      User = {
        { fqcn = "App\\Models\\User", path = "/src/Models/User.php" },
        { fqcn = "App\\Legacy\\User", path = "/legacy/User.php" },
      },
    }, result)
  end)

  it("should handle classes with no matches", function()
    vim.fn.system.returns("")

    local result = M.search_autoload_classmap({ { name = "NonexistentClass" } })

    assert.same({
      NonexistentClass = {},
    }, result)
  end)

  it("should use correct rg command", function()
    M.search_autoload_classmap({ { name = "User" } })

    local expected_command =
      string.format("rg '%s' %s", "/User.php", mock_root .. "/vendor/composer/autoload_classmap.php")
    assert.stub(vim.fn.system).was_called_with(expected_command)
  end)

  it("should handle malformed output", function()
    local mock_output = "This is not a valid autoload_classmap entry"
    vim.fn.system.returns(mock_output)

    local result = M.search_autoload_classmap({ { name = "User" } })

    assert.same({
      User = {},
    }, result)
  end)
end)
describe("get_insertion_point function", function()
  local mock_content

  before_each(function()
    mock_content = {}
    stub(api, "nvim_buf_get_lines").returns(mock_content)
    stub(vim.fn, "match")
  end)

  after_each(function()
    api.nvim_buf_get_lines:revert()
    vim.fn.match:revert()
  end)

  it("should return 2 for empty content", function()
    local result = M.get_insertion_point()
    assert.equals(2, result)
  end)

  it("should return last declare/namespace/use line + 1", function()
    mock_content = {
      "<?php",
      "declare(strict_types=1);",
      "namespace App\\Controllers;",
      "use App\\Models\\User;",
      "",
      "class UserController",
      "{",
      "    // Some code",
      "}",
    }
    vim.fn.match.on_call_with("declare(strict_types=1);", "^\\(declare\\|namespace\\|use\\)").returns(0)
    vim.fn.match.on_call_with("namespace App\\Controllers;", "^\\(declare\\|namespace\\|use\\)").returns(0)
    vim.fn.match.on_call_with("use App\\Models\\User;", "^\\(declare\\|namespace\\|use\\)").returns(0)
    vim.fn.match
      .on_call_with("class UserController", "^\\(class\\|final\\|interface\\|abstract\\|trait\\|enum\\)")
      .returns(0)

    local result = M.get_insertion_point()
    assert.equals(4, result)
  end)

  it("should return insertion point before class-like declaration", function()
    mock_content = {
      "<?php",
      "",
      "namespace App\\Controllers;",
      "",
      "use App\\Models\\User;",
      "",
      "final class UserController",
      "{",
      "    // Some code",
      "}",
    }
    vim.fn.match.on_call_with("namespace App\\Controllers;", "^\\(declare\\|namespace\\|use\\)").returns(0)
    vim.fn.match.on_call_with("use App\\Models\\User;", "^\\(declare\\|namespace\\|use\\)").returns(0)
    vim.fn.match
      .on_call_with("final class UserController", "^\\(class\\|final\\|interface\\|abstract\\|trait\\|enum\\)")
      .returns(0)

    local result = M.get_insertion_point()
    assert.equals(5, result)
  end)

  it("should handle files with only class-like declarations", function()
    mock_content = {
      "<?php",
      "",
      "class UserController",
      "{",
      "    // Some code",
      "}",
    }
    vim.fn.match
      .on_call_with("class UserController", "^\\(class\\|final\\|interface\\|abstract\\|trait\\|enum\\)")
      .returns(0)

    local result = M.get_insertion_point()
    assert.equals(2, result)
  end)

  it("should handle files with mixed content before class-like declaration", function()
    mock_content = {
      "<?php",
      "",
      "// Some comments",
      "use App\\Models\\User;",
      "// More comments",
      "namespace App\\Controllers;",
      "",
      "class UserController",
      "{",
      "    // Some code",
      "}",
    }
    vim.fn.match.on_call_with("use App\\Models\\User;", "^\\(declare\\|namespace\\|use\\)").returns(0)
    vim.fn.match.on_call_with("namespace App\\Controllers;", "^\\(declare\\|namespace\\|use\\)").returns(0)
    vim.fn.match
      .on_call_with("class UserController", "^\\(class\\|final\\|interface\\|abstract\\|trait\\|enum\\)")
      .returns(0)

    local result = M.get_insertion_point()
    assert.equals(6, result)
  end)
end)
describe("process_classmap_results function", function()
  local mock_callback
  local mock_transform_path
  local mock_vim_ui_select
  local mock_vim_fn_fnamemodify

  before_each(function()
    mock_callback = spy.new(function() end)
    mock_transform_path = stub(M, "transform_path")
    mock_vim_ui_select = stub(vim.ui, "select")
    mock_vim_fn_fnamemodify = stub(vim.fn, "fnamemodify")
  end)

  after_each(function()
    mock_transform_path:revert()
    mock_vim_ui_select:revert()
    mock_vim_fn_fnamemodify:revert()
  end)

  it("should handle multiple paths and user selects a valid path", function()
    local paths = {
      { fqcn = "App\\Models\\User", path = "/src/Models/User.php" },
      { fqcn = "App\\Legacy\\User", path = "/legacy/User.php" },
    }
    mock_vim_fn_fnamemodify.returns("/different/directory")
    mock_transform_path.returns("use App\\Models\\User;")
    mock_vim_ui_select.invokes(function(_, _, callback)
      callback(paths[1])
    end)

    local result = M.process_classmap_results(paths, "User", {}, "/workspace", "/current", mock_callback)

    assert.is_true(result)
    assert.stub(mock_callback).was_called_with("use App\\Models\\User;")
  end)

  it("should handle multiple paths and user selects an invalid path", function()
    local paths = {
      { fqcn = "App\\Models\\User", path = "/src/Models/User.php" },
      { fqcn = "App\\Legacy\\User", path = "/legacy/User.php" },
    }
    mock_vim_fn_fnamemodify.returns("/current")
    mock_vim_ui_select.invokes(function(_, _, callback)
      callback(paths[1])
    end)

    local result = M.process_classmap_results(paths, "User", {}, "/workspace", "/current", mock_callback)

    assert.is_true(result)
    assert.stub(mock_callback).was_called_with(nil)
  end)

  it("should handle single path in a different directory", function()
    local paths = {
      { fqcn = "App\\Models\\User", path = "/src/Models/User.php" },
    }
    mock_vim_fn_fnamemodify.returns("/different/directory")
    mock_transform_path.returns("use App\\Models\\User;")

    local result = M.process_classmap_results(paths, "User", {}, "/workspace", "/current", mock_callback)

    assert.is_true(result)
    assert.stub(mock_callback).was_called_with("use App\\Models\\User;")
  end)

  it("should handle single path in the same directory", function()
    local paths = {
      { fqcn = "App\\Models\\User", path = "/current/User.php" },
    }
    mock_vim_fn_fnamemodify.returns("/current")

    local result = M.process_classmap_results(paths, "User", {}, "/workspace", "/current", mock_callback)

    assert.is_false(result)
    assert.stub(mock_callback).was_not_called()
  end)

  it("should handle empty paths", function()
    local paths = {}

    local result = M.process_classmap_results(paths, "User", {}, "/workspace", "/current", mock_callback)

    assert.is_false(result)
    assert.stub(mock_callback).was_not_called()
  end)
end)
describe("process_file_search function", function()
  local mock_async_search_files
  local mock_transform_path
  local mock_callback
  local mock_vim_tbl_filter
  local mock_vim_tbl_map
  local mock_vim_ui_select
  local mock_vim_notify
  local mock_vim_fn_fnamemodify

  before_each(function()
    mock_async_search_files = stub(M, "async_search_files")
    mock_transform_path = stub(M, "transform_path")
    mock_callback = spy.new(function() end)
    mock_vim_tbl_filter = stub(vim, "tbl_filter")
    mock_vim_tbl_map = stub(vim, "tbl_map")
    mock_vim_ui_select = stub(vim.ui, "select")
    mock_vim_notify = stub(vim, "notify")
    mock_vim_fn_fnamemodify = stub(vim.fn, "fnamemodify")
  end)

  after_each(function()
    mock_async_search_files:revert()
    mock_transform_path:revert()
    mock_vim_tbl_filter:revert()
    mock_vim_tbl_map:revert()
    mock_vim_ui_select:revert()
    mock_vim_notify:revert()
    mock_vim_fn_fnamemodify:revert()
  end)

  it("should handle single matching file", function()
    local class_entry = { name = "TestClass" }
    local prefix = { { src = "src", prefix = "App\\" } }
    local workspace_root = "/workspace"
    local current_directory = "/workspace/src"

    mock_async_search_files.invokes(function(_, callback)
      callback({ "/workspace/src/TestClass.php" })
    end)
    mock_vim_tbl_filter.returns({ "/workspace/src/TestClass.php" })
    mock_vim_fn_fnamemodify.returns("/workspace/src")
    mock_transform_path.returns("use App\\TestClass;")

    M.process_file_search(class_entry, prefix, workspace_root, current_directory, mock_callback)

    assert.stub(mock_callback).was_called_with("use App\\TestClass;")
  end)

  it("should handle multiple matching files", function()
    local class_entry = { name = "TestClass" }
    local prefix = { { src = "src", prefix = "App\\" } }
    local workspace_root = "/workspace"
    local current_directory = "/workspace/src"

    mock_async_search_files.invokes(function(_, callback)
      callback({ "/workspace/src/TestClass.php", "/workspace/tests/TestClass.php" })
    end)
    mock_vim_tbl_map.returns({ "use App\\TestClass;", "use Tests\\TestClass;" })
    mock_vim_ui_select.invokes(function(_, _, callback)
      callback("use App\\TestClass;")
    end)

    M.process_file_search(class_entry, prefix, workspace_root, current_directory, mock_callback)

    assert.stub(mock_vim_ui_select).was_called()
    assert.stub(mock_callback).was_called_with("use App\\TestClass;")
  end)

  it("should handle no matching files", function()
    local class_entry = { name = "NonexistentClass" }
    local prefix = { { src = "src", prefix = "App\\" } }
    local workspace_root = "/workspace"
    local current_directory = "/workspace/src"

    mock_async_search_files.invokes(function(_, callback)
      callback({})
    end)

    M.process_file_search(class_entry, prefix, workspace_root, current_directory, mock_callback)

    assert
      .stub(mock_vim_notify)
      .was_called_with("No matches found for NonexistentClass", vim.log.levels.WARN, { title = "PhpNamespace" })
    assert.stub(mock_callback).was_called_with(nil)
  end)

  it("should handle file in current directory", function()
    local class_entry = { name = "TestClass" }
    local prefix = { { src = "src", prefix = "App\\" } }
    local workspace_root = "/workspace"
    local current_directory = "/workspace/src"

    mock_async_search_files.invokes(function(_, callback)
      callback({ "/workspace/src/TestClass.php" })
    end)
    mock_vim_tbl_filter.returns({})
    mock_vim_fn_fnamemodify.returns("/workspace/src")

    M.process_file_search(class_entry, prefix, workspace_root, current_directory, mock_callback)

    assert
      .stub(mock_vim_notify)
      .was_called_with("No matches found for TestClass", vim.log.levels.WARN, { title = "PhpNamespace" })
    assert.stub(mock_callback).was_called_with(nil)
  end)

  it("should handle class name with backslashes", function()
    local class_entry = { name = "Namespace\\TestClass" }
    local prefix = { { src = "src", prefix = "App\\" } }
    local workspace_root = "/workspace"
    local current_directory = "/workspace/src"

    mock_async_search_files.invokes(function(_, callback)
      callback({ "/workspace/src/Namespace/TestClass.php" })
    end)
    mock_vim_tbl_filter.returns({ "/workspace/src/Namespace/TestClass.php" })
    mock_vim_fn_fnamemodify.returns("/workspace/src/Namespace")
    mock_transform_path.returns("use App\\Namespace\\TestClass;")

    M.process_file_search(class_entry, prefix, workspace_root, current_directory, mock_callback)

    assert.stub(mock_callback).was_called_with("use App\\Namespace\\TestClass;")
  end)
end)
describe("process_class_queue function", function()
  local mock_queue
  local mock_prefix
  local mock_workspace_root
  local mock_current_directory
  local mock_callback
  local mock_process_single_class

  before_each(function()
    mock_queue = {
      is_empty = stub(),
      pop = stub(),
    }
    mock_prefix = { { src = "src", prefix = "App\\" } }
    mock_workspace_root = "/workspace"
    mock_current_directory = "/workspace/src"
    mock_callback = spy.new(function() end)
    mock_process_single_class = stub(M, "process_single_class")
  end)

  after_each(function()
    mock_process_single_class:revert()
  end)

  it("should process an empty queue", function()
    mock_queue.is_empty.returns(true)

    M.process_class_queue(mock_queue, mock_prefix, mock_workspace_root, mock_current_directory, mock_callback)

    assert.stub(mock_callback).was_called_with({})
    assert.stub(mock_process_single_class).was_not_called()
  end)

  it("should process a queue with one class", function()
    mock_queue.is_empty.returns(false).returns(true)
    mock_queue.pop.returns({ name = "TestClass" })
    mock_process_single_class.invokes(function(_, _, _, _, callback)
      callback("use App\\TestClass;")
    end)

    M.process_class_queue(mock_queue, mock_prefix, mock_workspace_root, mock_current_directory, mock_callback)

    assert.stub(mock_process_single_class).was_called(1)
    assert.stub(mock_callback).was_called_with({ "use App\\TestClass;" })
  end)

  it("should process a queue with multiple classes", function()
    mock_queue.is_empty.returns(false).returns(false).returns(true)
    mock_queue.pop.returns({ name = "TestClass1" }).returns({ name = "TestClass2" })
    mock_process_single_class
      .invokes(function(_, _, _, _, callback)
        callback("use App\\TestClass1;")
      end)
      .invokes(function(_, _, _, _, callback)
        callback("use App\\TestClass2;")
      end)

    M.process_class_queue(mock_queue, mock_prefix, mock_workspace_root, mock_current_directory, mock_callback)

    assert.stub(mock_process_single_class).was_called(2)
    assert.stub(mock_callback).was_called_with({ "use App\\TestClass1;", "use App\\TestClass2;" })
  end)

  it("should handle classes that don't produce use statements", function()
    mock_queue.is_empty.returns(false).returns(false).returns(true)
    mock_queue.pop.returns({ name = "TestClass1" }).returns({ name = "TestClass2" })
    mock_process_single_class
      .invokes(function(_, _, _, _, callback)
        callback(nil)
      end)
      .invokes(function(_, _, _, _, callback)
        callback("use App\\TestClass2;")
      end)

    M.process_class_queue(mock_queue, mock_prefix, mock_workspace_root, mock_current_directory, mock_callback)

    assert.stub(mock_process_single_class).was_called(2)
    assert.stub(mock_callback).was_called_with({ "use App\\TestClass2;" })
  end)

  it("should handle errors in process_single_class", function()
    mock_queue.is_empty.returns(false).returns(true)
    mock_queue.pop.returns({ name = "ErrorClass" })
    mock_process_single_class.invokes(function(_, _, _, _, callback)
      error("Test error")
    end)

    assert.has_error(function()
      M.process_class_queue(mock_queue, mock_prefix, mock_workspace_root, mock_current_directory, mock_callback)
    end, "Test error")

    assert.stub(mock_callback).was_not_called()
  end)
end)
describe("getClass function", function()
  local mock_has_composer_json
  local mock_expand
  local mock_get_namespaces
  local mock_get_insertion_point
  local mock_get_current_file_directory
  local mock_process_class_queue
  local mock_notify
  local mock_nvim_buf_set_lines
  local mock_NS

  before_each(function()
    mock_has_composer_json = stub(M, "has_composer_json")
    mock_expand = stub(vim.fn, "expand")
    mock_get_namespaces = stub(M, "get_namespaces")
    mock_get_insertion_point = stub(M, "get_insertion_point")
    mock_get_current_file_directory = stub(M, "get_current_file_directory")
    mock_process_class_queue = stub(M, "process_class_queue")
    mock_notify = stub(vim, "notify")
    mock_nvim_buf_set_lines = stub(api, "nvim_buf_set_lines")
    mock_NS = {
      get_prefix_and_src = stub(),
    }
    _G.NS = mock_NS
    _G.native = { "NativeClass" }
    _G.root = "/workspace"
  end)

  after_each(function()
    mock_has_composer_json:revert()
    mock_expand:revert()
    mock_get_namespaces:revert()
    mock_get_insertion_point:revert()
    mock_get_current_file_directory:revert()
    mock_process_class_queue:revert()
    mock_notify:revert()
    mock_nvim_buf_set_lines:revert()
  end)

  it("should return early if composer.json is not found", function()
    mock_has_composer_json.returns(false)

    M.getClass()

    assert
      .stub(mock_notify)
      .was_called_with("composer.json not found ", vim.log.levels.WARN, { title = "PhpNamespace" })
  end)

  it("should return early if no word is under cursor", function()
    mock_has_composer_json.returns(true)
    mock_expand.returns("")

    M.getClass()

    assert.stub(mock_notify).was_called_with("No word under cursor", vim.log.levels.WARN, { title = "PhpNamespace" })
  end)

  it("should return early if class is already used", function()
    mock_has_composer_json.returns(true)
    mock_expand.returns("ExistingClass")
    mock_get_namespaces.returns({ { name = "ExistingClass" } })

    M.getClass()

    assert
      .stub(mock_notify)
      .was_called_with("Class 'ExistingClass' is already used", vim.log.levels.INFO, { title = "PhpNamespace" })
  end)

  it("should add native class use statement", function()
    mock_has_composer_json.returns(true)
    mock_expand.returns("NativeClass")
    mock_get_namespaces.returns({})
    mock_get_insertion_point.returns(3)

    M.getClass()

    assert.stub(mock_nvim_buf_set_lines).was_called_with(0, 3, 3, false, { "use NativeClass;" })
    assert
      .stub(mock_notify)
      .was_called_with("Added native class: NativeClass", vim.log.levels.INFO, { title = "PhpNamespace" })
  end)

  it("should process non-native class", function()
    mock_has_composer_json.returns(true)
    mock_expand.returns("CustomClass")
    mock_get_namespaces.returns({})
    mock_get_insertion_point.returns(3)
    mock_get_current_file_directory.returns("/workspace/src")
    mock_NS.get_prefix_and_src.returns({ { src = "src", prefix = "App\\" } })

    mock_process_class_queue.invokes(function(_, _, _, _, callback)
      callback({ "use App\\CustomClass;" })
    end)

    M.getClass()

    assert.stub(mock_process_class_queue).was_called()
    assert.stub(mock_nvim_buf_set_lines).was_called_with(0, 3, 3, false, { "use App\\CustomClass;" })
  end)

  it("should handle empty result from process_class_queue", function()
    mock_has_composer_json.returns(true)
    mock_expand.returns("UnknownClass")
    mock_get_namespaces.returns({})
    mock_get_insertion_point.returns(3)
    mock_get_current_file_directory.returns("/workspace/src")
    mock_NS.get_prefix_and_src.returns({ { src = "src", prefix = "App\\" } })

    mock_process_class_queue.invokes(function(_, _, _, _, callback)
      callback({})
    end)

    M.getClass()

    assert.stub(mock_process_class_queue).was_called()
    assert.stub(mock_nvim_buf_set_lines).was_called_with(0, 3, 3, false, {})
  end)
end)
describe("M.getClasses", function()
  local M = require("namespace.main")
  local NS = require("namespace.nsgen")
  local Queue = require("namespace.queue")

  before_each(function()
    stub(M, "has_composer_json")
    stub(M, "get_filtered_classes")
    stub(M, "get_insertion_point")
    stub(NS, "get_prefix_and_src")
    stub(M, "get_current_file_directory")
    stub(M, "process_class_queue")
    stub(vim, "notify")
    stub(vim.api, "nvim_buf_set_lines")
  end)

  after_each(function()
    M.has_composer_json:revert()
    M.get_filtered_classes:revert()
    M.get_insertion_point:revert()
    NS.get_prefix_and_src:revert()
    M.get_current_file_directory:revert()
    M.process_class_queue:revert()
    vim.notify:revert()
    vim.api.nvim_buf_set_lines:revert()
  end)

  it("should return early if composer.json is not found", function()
    M.has_composer_json.returns(false)
    M.getClasses()
    assert.stub(vim.notify).was_called_with("composer.json not found ", vim.log.levels.WARN, { title = "PhpNamespace" })
    assert.stub(M.get_filtered_classes).was_not_called()
  end)

  it("should return early if no filtered classes are found", function()
    M.has_composer_json.returns(true)
    M.get_filtered_classes.returns(nil, {})
    M.getClasses()
    assert
      .stub(vim.notify)
      .was_called_with("No classes found to process", vim.log.levels.WARN, { title = "PhpNamespace" })
    assert.stub(M.get_insertion_point).was_not_called()
  end)

  it("should process native classes and filtered classes", function()
    M.has_composer_json.returns(true)
    M.get_filtered_classes.returns({ { name = "FilteredClass" } }, { { name = "NativeClass" } })
    M.get_insertion_point.returns(5)
    NS.get_prefix_and_src.returns({ prefix = "Test\\", src = "src" })
    M.get_current_file_directory.returns("/test/dir")

    M.process_class_queue.invokes(function(queue, prefix, workspace_root, current_directory, callback)
      callback({ "use Test\\FilteredClass;" })
    end)

    M.getClasses()

    assert.stub(vim.api.nvim_buf_set_lines).was_called_with(0, 5, 5, false, {
      "use NativeClass;",
      "use Test\\FilteredClass;",
    })
  end)

  it("should handle empty native classes", function()
    M.has_composer_json.returns(true)
    M.get_filtered_classes.returns({ { name = "FilteredClass" } }, {})
    M.get_insertion_point.returns(3)
    NS.get_prefix_and_src.returns({ prefix = "App\\", src = "app" })
    M.get_current_file_directory.returns("/app/dir")

    M.process_class_queue.invokes(function(queue, prefix, workspace_root, current_directory, callback)
      callback({ "use App\\FilteredClass;" })
    end)

    M.getClasses()

    assert.stub(vim.api.nvim_buf_set_lines).was_called_with(0, 3, 3, false, {
      "use App\\FilteredClass;",
    })
  end)

  it("should handle multiple filtered classes", function()
    M.has_composer_json.returns(true)
    M.get_filtered_classes.returns({ { name = "Class1" }, { name = "Class2" } }, { { name = "NativeClass" } })
    M.get_insertion_point.returns(2)
    NS.get_prefix_and_src.returns({ prefix = "Vendor\\", src = "vendor" })
    M.get_current_file_directory.returns("/vendor/dir")

    M.process_class_queue.invokes(function(queue, prefix, workspace_root, current_directory, callback)
      callback({ "use Vendor\\Class1;", "use Vendor\\Class2;" })
    end)

    M.getClasses()

    assert.stub(vim.api.nvim_buf_set_lines).was_called_with(0, 2, 2, false, {
      "use NativeClass;",
      "use Vendor\\Class1;",
      "use Vendor\\Class2;",
    })
  end)
end)
