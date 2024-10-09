local namespace = require("tests.namespace.mainTest")
local stub = require("luassert.stub")

describe("mainTest", function()
  describe("get_filtered_classes", function()
    local original_table_remove_duplicates
    local original_table_contains2
    local original_tbl_contains

    before_each(function()
      original_table_remove_duplicates = table.remove_duplicates
      original_table_contains2 = table.contains2
      original_tbl_contains = vim.tbl_contains

      table.remove_duplicates = stub.new()
      table.contains2 = stub.new()
      vim.tbl_contains = stub.new()

      stub(namespace, "get_classes_from_tree")
      stub(namespace, "get_namespaces")
    end)

    after_each(function()
      table.remove_duplicates = original_table_remove_duplicates
      table.contains2 = original_table_contains2
      vim.tbl_contains = original_tbl_contains

      namespace.get_classes_from_tree:revert()
      namespace.get_namespaces:revert()
    end)

    it("should filter out namespace classes and native classes", function()
      namespace.get_classes_from_tree.returns({
        { name = "Class1" },
        { name = "Class2" },
        { name = "NativeClass" },
        { name = "Class3" },
      })
      table.remove_duplicates.returns({
        { name = "Class1" },
        { name = "Class2" },
        { name = "NativeClass" },
        { name = "Class3" },
      })
      namespace.get_namespaces.returns({
        { name = "Class2", ns = "Namespace\\Class2" },
      })
      table.contains2.returns(false).on_call_with({ { name = "Class2", ns = "Namespace\\Class2" } }, "Class1")
      table.contains2.returns(true).on_call_with({ { name = "Class2", ns = "Namespace\\Class2" } }, "Class2")
      table.contains2.returns(false).on_call_with({ { name = "Class2", ns = "Namespace\\Class2" } }, "NativeClass")
      table.contains2.returns(false).on_call_with({ { name = "Class2", ns = "Namespace\\Class2" } }, "Class3")
      vim.tbl_contains.returns(true).on_call_with(namespace.native, "NativeClass")
      vim.tbl_contains.returns(false).on_call_with(namespace.native, "Class1")
      vim.tbl_contains.returns(false).on_call_with(namespace.native, "Class3")

      local filtered_classes, native_classes = namespace.get_filtered_classes()

      assert.same({ { name = "Class1" }, { name = "Class3" } }, filtered_classes)
      assert.same({ { name = "NativeClass" } }, native_classes)
    end)

    it("should handle empty input", function()
      namespace.get_classes_from_tree.returns({})
      table.remove_duplicates.returns({})
      namespace.get_namespaces.returns({})

      local filtered_classes, native_classes = namespace.get_filtered_classes()

      assert.same({}, filtered_classes)
      assert.same({}, native_classes)
    end)

    it("should handle all classes being filtered out", function()
      namespace.get_classes_from_tree.returns({
        { name = "Class1" },
        { name = "Class2" },
      })
      table.remove_duplicates.returns({
        { name = "Class1" },
        { name = "Class2" },
      })
      namespace.get_namespaces.returns({
        { name = "Class1", ns = "Namespace\\Class1" },
        { name = "Class2", ns = "Namespace\\Class2" },
      })
      table.contains2.returns(true)
      vim.tbl_contains.returns(false)

      local filtered_classes, native_classes = namespace.get_filtered_classes()

      assert.same({}, filtered_classes)
      assert.same({}, native_classes)
    end)

    it("should handle all classes being native", function()
      namespace.get_classes_from_tree.returns({
        { name = "NativeClass1" },
        { name = "NativeClass2" },
      })
      table.remove_duplicates.returns({
        { name = "NativeClass1" },
        { name = "NativeClass2" },
      })
      namespace.get_namespaces.returns({})
      table.contains2.returns(false)
      vim.tbl_contains.returns(true)

      local filtered_classes, native_classes = namespace.get_filtered_classes()

      assert.same({}, filtered_classes)
      assert.same({ { name = "NativeClass1" }, { name = "NativeClass2" } }, native_classes)
    end)
  end)
end)
