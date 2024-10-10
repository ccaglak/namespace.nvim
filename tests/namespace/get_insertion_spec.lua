local namespace = require("tests.namespace.mainTest")
local mock = require("luassert.mock")
local stub = require("luassert.stub")
local api = mock(vim.api, true)

describe("mainTest", function()
  describe("get_insertion_point", function()
    local original_match

    before_each(function()
      original_match = vim.fn.match
      vim.fn.match = stub.new(vim.fn, "match")
      api.nvim_buf_get_lines = stub.new()
    end)

    after_each(function()
      vim.fn.match = original_match
      mock.revert(api)
    end)

    it("should return 2 when no relevant lines are found", function()
      api.nvim_buf_get_lines.returns({
        "<?php",
        "",
        "// Some comment",
        "function test() {",
        "}",
      })
      vim.fn.match.returns(-1)

      local result = namespace.get_insertion_point()

      assert.are.equal(2, result)
    end)

    it("should return correct insertion point for use statements", function()
      api.nvim_buf_get_lines.returns({
        "<?php",
        "",
        "use Namespace\\Class1;",
        "use Namespace\\Class2;",
        "class TestClass {",
        "}",
      })
      vim.fn.match.returns(0).on_call_with("use Namespace\\Class1;", "^\\(declare\\|namespace\\|use\\)")
      vim.fn.match.returns(0).on_call_with("use Namespace\\Class2;", "^\\(declare\\|namespace\\|use\\)")
      vim.fn.match
        .returns(0)
        .on_call_with("class TestClass {", "^\\(class\\|final\\|interface\\|abstract\\|trait\\|enum\\)")

      local result = namespace.get_insertion_point()
      assert.are.equal(4, result)
    end)

    it("should handle namespace declaration", function()
      api.nvim_buf_get_lines.returns({
        "<?php",
        "",
        "namespace App\\Controller;",
        "",
        "use Namespace\\Class1;",
        "class TestClass {",
        "}",
      })
      vim.fn.match.returns(0).on_call_with("namespace App\\Controller;", "^\\(declare\\|namespace\\|use\\)")
      vim.fn.match.returns(0).on_call_with("use Namespace\\Class1;", "^\\(declare\\|namespace\\|use\\)")
      vim.fn.match
        .returns(0)
        .on_call_with("class TestClass {", "^\\(class\\|final\\|interface\\|abstract\\|trait\\|enum\\)")

      local result = namespace.get_insertion_point()

      assert.are.equal(5, result)
    end)

    it("should handle declare statement", function()
      api.nvim_buf_get_lines.returns({
        "<?php",
        "declare(strict_types=1);",
        "",
        "namespace App\\Controller;",
        "",
        "class TestClass {",
        "}",
      })
      vim.fn.match.returns(0).on_call_with("declare(strict_types=1);", "^\\(declare\\|namespace\\|use\\)")
      vim.fn.match.returns(0).on_call_with("namespace App\\Controller;", "^\\(declare\\|namespace\\|use\\)")
      vim.fn.match
        .returns(0)
        .on_call_with("class TestClass {", "^\\(class\\|final\\|interface\\|abstract\\|trait\\|enum\\)")

      local result = namespace.get_insertion_point()

      assert.are.equal(4, result)
    end)

    it("should handle interface declaration", function()
      api.nvim_buf_get_lines.returns({
        "<?php",
        "",
        "use Namespace\\Class1;",
        "interface TestInterface {",
        "}",
      })
      vim.fn.match.returns(0).on_call_with("use Namespace\\Class1;", "^\\(declare\\|namespace\\|use\\)")
      vim.fn.match
        .returns(0)
        .on_call_with("interface TestInterface {", "^\\(class\\|final\\|interface\\|abstract\\|trait\\|enum\\)")

      local result = namespace.get_insertion_point()

      assert.are.equal(3, result)
    end)
  end)
end)
