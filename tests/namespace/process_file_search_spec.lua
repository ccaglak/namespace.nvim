-- local namespace = require("namespace.mainTest")
-- local mock = require("luassert.mock")
-- local stub = require("luassert.stub")

-- describe("mainTest", function()
--   describe("process_file_search", function()
--     local callback, class_entry, prefix, workspace_root, current_directory

--     before_each(function()
--       callback = stub.new()
--       class_entry = { name = "TestClass" }
--       prefix = { { src = "src", prefix = "App\\" } }
--       workspace_root = "/home/user/project"
--       current_directory = "/home/user/project/src"
--       stub(namespace, "async_search_files")
--       stub(namespace, "transform_path")
--       stub(vim, "notify")
--       stub(vim.ui, "select")
--     end)

--     after_each(function()
--       namespace.async_search_files:revert()
--       namespace.transform_path:revert()
--       mock.revert(vim)
--     end)

--     it("should call callback with single matching file", function()
--       namespace.async_search_files.invokes(function(pattern, cb)
--         cb({ "/home/user/project/src/TestClass.php" })
--       end)
--       namespace.transform_path.returns("use App\\TestClass;")

--       namespace.process_file_search(class_entry, prefix, workspace_root, current_directory, callback)

--       assert.stub(callback).was_called_with("use App\\TestClass;")
--     end)

--     it("should filter out files in current directory", function()
--       namespace.async_search_files.invokes(function(pattern, cb)
--         cb({ "/home/user/project/src/TestClass.php", "/home/user/project/tests/TestClass.php" })
--       end)
--       namespace.transform_path.returns("use Tests\\TestClass;")

--       namespace.process_file_search(class_entry, prefix, workspace_root, current_directory, callback)

--       assert.stub(callback).was_called_with("use Tests\\TestClass;")
--     end)

--     it("should prompt user selection for multiple matching files", function()
--       namespace.async_search_files.invokes(function(pattern, cb)
--         cb({ "/home/user/project/src1/TestClass.php", "/home/user/project/src2/TestClass.php" })
--       end)
--       namespace.transform_path.returns("use App\\TestClass;")
--       vim.ui.select.invokes(function(items, opts, cb)
--         cb(items[1])
--       end)

--       namespace.process_file_search(class_entry, prefix, workspace_root, current_directory, callback)

--       assert.stub(vim.ui.select).was_called()
--       assert.stub(callback).was_called_with("use App\\TestClass;")
--     end)

--     it("should notify when no matches are found", function()
--       namespace.async_search_files.invokes(function(pattern, cb)
--         cb({})
--       end)

--       namespace.process_file_search(class_entry, prefix, workspace_root, current_directory, callback)

--       assert
--           .stub(vim.notify)
--           .was_called_with("No matches found for TestClass", vim.log.levels.WARN, { title = "PhpNamespace" })
--       assert.stub(callback).was_called_with(nil)
--     end)

--     it("should handle user cancellation in multiple file scenario", function()
--       namespace.async_search_files.invokes(function(pattern, cb)
--         cb({ "/home/user/project/src1/TestClass.php", "/home/user/project/src2/TestClass.php" })
--       end)
--       namespace.transform_path.returns("use App\\TestClass;")
--       vim.ui.select.invokes(function(items, opts, cb)
--         cb(nil)
--       end)

--       namespace.process_file_search(class_entry, prefix, workspace_root, current_directory, callback)

--       assert.stub(callback).was_called_with(nil)
--     end)
--   end)
-- end)
