describe("get_filtered_classes", function()
  local M = require("tests.namespace.mainTest")
  local native = require("namespace.native")

  before_each(function()
    -- Mock the necessary functions
    M.get_classes_from_tree = function()
      return {
        { name = "TestClass" },
        { name = "NativeClass" },
        { name = "AnotherClass" },
        { name = "TestClass" }, -- Duplicate to test removal
      }
    end

    M.get_namespaces = function()
      return {
        { name = "NamespaceClass", ns = "Some\\Namespace" },
      }
    end

    -- Add a native class to the native table for testing
    table.insert(native, "NativeClass")
  end)

  it("should remove duplicate classes", function()
    local filtered, native_classes = M.get_filtered_classes()
    assert.are.equal(2, #filtered)
  end)

  it("should remove classes from namespaces", function()
    local filtered, native_classes = M.get_filtered_classes()
    assert.is_nil(vim.tbl_filter(function(class)
      return class.name == "NamespaceClass"
    end, filtered)[1])
  end)

  it("should separate native classes", function()
    local filtered, native_classes = M.get_filtered_classes()
    assert.are.equal(1, #native_classes)
    assert.are.equal("NativeClass", native_classes[1].name)
  end)

  it("should return correct filtered classes", function()
    local filtered, native_classes = M.get_filtered_classes()
    assert.are.same({ { name = "TestClass" }, { name = "AnotherClass" } }, filtered)
  end)
end)
