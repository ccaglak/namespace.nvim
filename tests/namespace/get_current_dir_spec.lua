local namespace = require("tests.namespace.mainTest")
local stub = require("luassert.stub")

describe("mainTest", function()
  describe("get_current_file_directory", function()
    local original_expand
    local original_fnamemodify

    before_each(function()
      original_expand = vim.fn.expand
      original_fnamemodify = vim.fn.fnamemodify
      vim.fn.expand = stub.new(vim.fn, "expand")
      vim.fn.fnamemodify = stub.new(vim.fn, "fnamemodify")
      stub.new(namespace, "get_project_root")
    end)

    after_each(function()
      vim.fn.expand = original_expand
      vim.fn.fnamemodify = original_fnamemodify
      namespace.get_project_root:revert()
    end)

    it("should return the current file directory relative to project root", function()
      vim.fn.expand.returns("/home/user/project/lua/namespace/mainTest.lua")
      vim.fn.fnamemodify.returns("/home/user/project/lua/namespace")
      namespace.get_project_root.returns("/home/user/project")

      local result = namespace.get_current_file_directory()

      assert.are.equal("/lua/namespace", result)
      assert.stub(vim.fn.expand).was_called_with("%:p")
      assert.stub(vim.fn.fnamemodify).was_called_with("/home/user/project/lua/namespace/mainTest.lua", ":h")
      assert.stub(namespace.get_project_root).was_called()
    end)

    it("should handle root directory case", function()
      vim.fn.expand.returns("/home/user/project/main.lua")
      vim.fn.fnamemodify.returns("/home/user/project")
      namespace.get_project_root.returns("/home/user/project")

      local result = namespace.get_current_file_directory()

      assert.are.equal("", result)
    end)

    it("should handle subdirectories", function()
      vim.fn.expand.returns("/home/user/project/src/utils/helper.lua")
      vim.fn.fnamemodify.returns("/home/user/project/src/utils")
      namespace.get_project_root.returns("/home/user/project")

      local result = namespace.get_current_file_directory()

      assert.are.equal("/src/utils", result)
    end)
  end)
end)
