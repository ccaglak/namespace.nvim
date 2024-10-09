local namespace = require("namespace.mainTest")
local mock = require("luassert.mock")
local stub = require("luassert.stub")
local ts = mock(require("nvim-treesitter"), true)
local api = mock(vim.api, true)

describe("mainTest", function()
  describe("has_composer_json", function()
    local original_filereadable

    before_each(function()
      original_filereadable = vim.fn.filereadable
      vim.fn.filereadable = stub.new(vim.fn, "filereadable")
      stub(namespace, "get_project_root")
    end)

    after_each(function()
      vim.fn.filereadable = original_filereadable
      namespace.get_project_root:revert()
    end)

    it("should return true when composer.json exists", function()
      namespace.get_project_root.returns("/home/user/project")
      vim.fn.filereadable.returns(1)

      local result = namespace.has_composer_json()

      assert.is_true(result)
      assert.stub(vim.fn.filereadable).was_called_with("/home/user/project/composer.json")
    end)

    it("should return false when composer.json does not exist", function()
      namespace.get_project_root.returns("/home/user/project")
      vim.fn.filereadable.returns(0)

      local result = namespace.has_composer_json()

      assert.is_false(result)
      assert.stub(vim.fn.filereadable).was_called_with("/home/user/project/composer.json")
    end)

    it("should handle different project roots", function()
      namespace.get_project_root.returns("/var/www/html")
      vim.fn.filereadable.returns(1)

      local result = namespace.has_composer_json()

      assert.is_true(result)
      assert.stub(vim.fn.filereadable).was_called_with("/var/www/html/composer.json")
    end)

    it("should handle empty project root", function()
      namespace.get_project_root.returns("")
      vim.fn.filereadable.returns(0)

      local result = namespace.has_composer_json()

      assert.is_false(result)
      assert.stub(vim.fn.filereadable).was_called_with("/composer.json")
    end)
  end)
end)
