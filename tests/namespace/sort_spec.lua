local namespace = require("namespace.sort")
local mock = require("luassert.mock")
local stub = require("luassert.stub")

describe("sort", function()
  describe("sortUseStatements", function()
    local original_nvim_buf_get_lines
    local original_nvim_buf_set_lines

    before_each(function()
      original_nvim_buf_get_lines = vim.api.nvim_buf_get_lines
      original_nvim_buf_set_lines = vim.api.nvim_buf_set_lines
      vim.api.nvim_buf_get_lines = stub.new(vim.api, "nvim_buf_get_lines")
      vim.api.nvim_buf_set_lines = stub.new(vim.api, "nvim_buf_set_lines")
    end)

    after_each(function()
      vim.api.nvim_buf_get_lines = original_nvim_buf_get_lines
      vim.api.nvim_buf_set_lines = original_nvim_buf_set_lines
    end)

    it("should not sort when on_save is false", function()
      local sort = { on_save = false }
      namespace.sortUseStatements(sort)
      assert.stub(vim.api.nvim_buf_get_lines).was_not_called()
      assert.stub(vim.api.nvim_buf_set_lines).was_not_called()
    end)

    it("should sort use statements when on_save is true", function()
      local sort = { on_save = true, sort_type = "natural" }
      vim.api.nvim_buf_get_lines.returns({
        "<?php",
        "",
        "use Namespace\\ClassC;",
        "use Namespace\\ClassA;",
        "use Namespace\\ClassB;",
        "",
        "class TestClass {",
        "}",
      })

      namespace.sortUseStatements(sort)

      assert.stub(vim.api.nvim_buf_get_lines).was_called_with(0, 0, 50, false)
      assert.stub(vim.api.nvim_buf_set_lines).was_called_with(0, 2, 5, false, {
        "use Namespace\\ClassA;",
        "use Namespace\\ClassB;",
        "use Namespace\\ClassC;",
      })
    end)

    it("should not modify when no use statements are found", function()
      local sort = { on_save = true, sort_type = "natural" }
      vim.api.nvim_buf_get_lines.returns({
        "<?php",
        "",
        "class TestClass {",
        "}",
      })

      namespace.sortUseStatements(sort)

      assert.stub(vim.api.nvim_buf_get_lines).was_called_with(0, 0, 50, false)
      assert.stub(vim.api.nvim_buf_set_lines).was_not_called()
    end)

    it("should handle use statements with different namespaces", function()
      local sort = { on_save = true, sort_type = "natural" }
      vim.api.nvim_buf_get_lines.returns({
        "<?php",
        "",
        "use Namespace2\\ClassB;",
        "use Namespace1\\ClassA;",
        "use Namespace3\\ClassC;",
        "",
        "class TestClass {",
        "}",
      })

      namespace.sortUseStatements(sort)

      assert.stub(vim.api.nvim_buf_get_lines).was_called_with(0, 0, 50, false)
      assert.stub(vim.api.nvim_buf_set_lines).was_called_with(0, 2, 5, false, {
        "use Namespace1\\ClassA;",
        "use Namespace2\\ClassB;",
        "use Namespace3\\ClassC;",
      })
    end)

    it("should handle use statements with aliases", function()
      local sort = { on_save = true, sort_type = "natural" }
      vim.api.nvim_buf_get_lines.returns({
        "<?php",
        "",
        "use Namespace\\ClassC as AliasC;",
        "use Namespace\\ClassA as AliasA;",
        "use Namespace\\ClassB;",
        "",
        "class TestClass {",
        "}",
      })

      namespace.sortUseStatements(sort)

      assert.stub(vim.api.nvim_buf_get_lines).was_called_with(0, 0, 50, false)
      assert.stub(vim.api.nvim_buf_set_lines).was_called_with(0, 2, 5, false, {
        "use Namespace\\ClassA as AliasA;",
        "use Namespace\\ClassB;",
        "use Namespace\\ClassC as AliasC;",
      })
    end)
  end)
end)
