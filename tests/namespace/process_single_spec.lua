local namespace = require("tests.namespace.mainTest")
local stub = require("luassert.stub")

describe("mainTest", function()
  describe("process_single_class", function()
    local callback, class_entry, prefix, workspace_root, current_directory

    before_each(function()
      callback = stub.new()
      class_entry = { name = "TestClass" }
      prefix = { { src = "src", prefix = "App\\" } }
      workspace_root = "/home/user/project"
      current_directory = "/home/user/project/src"
      stub(namespace, "search_autoload_classmap")
      stub(namespace, "process_classmap_results")
      stub(namespace, "process_file_search")
    end)

    after_each(function()
      namespace.search_autoload_classmap:revert()
      namespace.process_classmap_results:revert()
      namespace.process_file_search:revert()
    end)

    it("should process classmap results when available", function()
      namespace.search_autoload_classmap.returns({ TestClass = { { path = "/path/to/TestClass.php" } } })
      namespace.process_classmap_results.returns(true)

      namespace.process_single_class(class_entry, prefix, workspace_root, current_directory, callback)

      assert
        .stub(namespace.process_classmap_results)
        .was_called_with({ { path = "/path/to/TestClass.php" } }, "TestClass", prefix, workspace_root, current_directory, callback)
      assert.stub(namespace.process_file_search).was_not_called()
    end)

    it("should fall back to file search when classmap processing returns false", function()
      namespace.search_autoload_classmap.returns({ TestClass = { { path = "/path/to/TestClass.php" } } })
      namespace.process_classmap_results.returns(false)

      namespace.process_single_class(class_entry, prefix, workspace_root, current_directory, callback)

      assert.stub(namespace.process_classmap_results).was_called()
      assert
        .stub(namespace.process_file_search)
        .was_called_with(class_entry, prefix, workspace_root, current_directory, callback)
    end)

    it("should perform file search when no classmap results are found", function()
      namespace.search_autoload_classmap.returns({})

      namespace.process_single_class(class_entry, prefix, workspace_root, current_directory, callback)

      assert.stub(namespace.process_classmap_results).was_not_called()
      assert
        .stub(namespace.process_file_search)
        .was_called_with(class_entry, prefix, workspace_root, current_directory, callback)
    end)

    it("should handle non-table classmap results", function()
      namespace.search_autoload_classmap.returns({ TestClass = "not a table" })

      namespace.process_single_class(class_entry, prefix, workspace_root, current_directory, callback)

      assert.stub(namespace.process_classmap_results).was_not_called()
      assert.stub(namespace.process_file_search).was_called()
    end)
  end)
end)
