local namespace = require("namespace.sort")
local mock = require("luassert.mock")
local stub = require("luassert.stub")
local api = mock(vim.api, true)

describe("sortTest", function()
  describe("sortUseStatements", function()
    local original_tbl_filter
    local config

    before_each(function()
      original_tbl_filter = vim.tbl_filter
      vim.tbl_filter = stub.new(vim, "tbl_filter")
      api.nvim_buf_get_lines = stub.new()
      api.nvim_buf_set_lines = stub.new()
      config = {
        sort_type = "alphabetical",
        remove_duplicates = false,
      }
    end)

    after_each(function()
      vim.tbl_filter = original_tbl_filter
      mock.revert(api)
    end)

    it("should sort use statements alphabetically", function()
      api.nvim_buf_get_lines.returns({
        "<?php",
        "use Zebra\\Stripes;",
        "use Apple\\Fruit;",
        "class TestClass {",
        "}",
      })
      vim.tbl_filter.returns({ "use Zebra\\Stripes;", "use Apple\\Fruit;" })

      namespace.sortUseStatements(config)

      assert.stub(api.nvim_buf_set_lines).was_called_with(0, 1, 3, false, {
        "use Apple\\Fruit;",
        "use Zebra\\Stripes;",
      })
    end)

    it("should handle empty use statements", function()
      api.nvim_buf_get_lines.returns({
        "<?php",
        "class TestClass {",
        "}",
      })
      vim.tbl_filter.returns({})

      namespace.sortUseStatements(config)

      assert.stub(api.nvim_buf_set_lines).was_not_called()
    end)

    it("should sort by length when configured", function()
      config.sort_type = "length"
      api.nvim_buf_get_lines.returns({
        "<?php",
        "use Very\\Long\\Namespace\\Class;",
        "use Short\\Class;",
        "class TestClass {",
        "}",
      })
      vim.tbl_filter.returns({ "use Very\\Long\\Namespace\\Class;", "use Short\\Class;" })

      namespace.sortUseStatements(config)

      assert.stub(api.nvim_buf_set_lines).was_called_with(0, 1, 3, false, {
        "use Short\\Class;",
        "use Very\\Long\\Namespace\\Class;",
      })
    end)
  end)
end)
