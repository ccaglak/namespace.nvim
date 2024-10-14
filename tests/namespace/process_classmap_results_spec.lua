local namespace = require("tests.namespace.mainTest")
local vui = require("namespace.ui").select
local stub = require("luassert.stub")

describe("mainTest", function()
  describe("process_classmap_results", function()
    local original_ui_select
    local original_fnamemodify
    local callback

    before_each(function()
      original_ui_select = vui
      original_fnamemodify = vim.fn.fnamemodify
      vui = stub.new()
      vim.fn.fnamemodify = stub.new()
      callback = stub.new()
      stub(namespace, "transform_path")
    end)

    after_each(function()
      vui = original_ui_select
      vim.fn.fnamemodify = original_fnamemodify
      namespace.transform_path:revert()
    end)

    it("should return false when paths is empty", function()
      local result = namespace.process_classmap_results({}, "TestClass", {}, "/workspace", "/current", callback)
      assert.is_false(result)
      assert.stub(callback).was_not_called()
    end)

    it("should process single path without user selection", function()
      vim.fn.fnamemodify.returns("/different")
      namespace.transform_path.returns("use Namespace\\TestClass;")

      local paths = { { fqcn = "Namespace\\TestClass", path = "/workspace/src/TestClass.php" } }
      local result = namespace.process_classmap_results(paths, "TestClass", {}, "/workspace", "/current", callback)

      assert.is_true(result)
      assert.stub(callback).was_called_with("use Namespace\\TestClass;")
      assert.stub(vim.ui.select).was_not_called()
    end)

    -- it("should to not process single path when in current directory", function()
    --   vim.fn.fnamemodify.returns("/current")
    --
    --   local paths = { { fqcn = "Namespace\\TestClass", path = "/workspace/current/TestClass.php" } }
    --   local result = namespace.process_classmap_results(paths, "TestClass", {}, "/workspace", "/current", callback)
    --
    --   assert.is_true(result)
    --   assert.stub(callback).was_called_with(nil)
    --   assert.stub(vim.ui.select).was_not_called()
    -- end)

    it("should prompt user selection for multiple paths", function()
      vim.fn.fnamemodify.returns("/different")
      namespace.transform_path.returns("use Namespace\\TestClass;")
      vim.ui.select.invokes(function(items, opts, cb)
        cb(items[2])
      end)

      local paths = {
        { fqcn = "Namespace1\\TestClass", path = "/workspace/src1/TestClass.php" },
        { fqcn = "Namespace2\\TestClass", path = "/workspace/src2/TestClass.php" },
      }
      local result = namespace.process_classmap_results(paths, "TestClass", {}, "/workspace", "/current", callback)

      assert.is_true(result)
      assert.stub(callback).was_called_with("use Namespace\\TestClass;")
      assert.stub(vui).was_called()
    end)

    it("should handle user cancellation in multiple paths scenario", function()
      vim.ui.select.invokes(function(items, opts, cb)
        cb(nil)
      end)

      local paths = {
        { fqcn = "Namespace1\\TestClass", path = "/workspace/src1/TestClass.php" },
        { fqcn = "Namespace2\\TestClass", path = "/workspace/src2/TestClass.php" },
      }
      local result = namespace.process_classmap_results(paths, "TestClass", {}, "/workspace", "/current", callback)

      assert.is_true(result)
      assert.stub(callback).was_called_with(nil)
    end)
  end)
end)
