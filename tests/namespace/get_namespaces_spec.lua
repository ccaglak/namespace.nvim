local namespace = require("tests.namespace.mainTest")
local mock = require("luassert.mock")
local stub = require("luassert.stub")
local api = mock(vim.api, true)

describe("mainTest", function()
  describe("get_namespaces", function()
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

    it("should return empty table when no use statements are found", function()
      api.nvim_buf_get_lines.returns({
        "<?php",
        "",
        "class TestClass {",
        "}",
      })
      vim.fn.match.returns(0)

      local result = namespace.get_namespaces()

      assert.same({}, result)
      assert.stub(api.nvim_buf_get_lines).was_called_with(0, 0, 50, false)
    end)

    it("should return use statements until class declaration", function()
      api.nvim_buf_get_lines.returns({
        "<?php",
        "",
        "use Namespace\\Class1;",
        "use Namespace\\Class2;",
        "class TestClass {",
        "}",
      })
      vim.fn.match
          .returns(-1)
          .on_call_with("use Namespace\\Class1;", "^\\(class\\|final\\|interface\\|abstract\\|trait\\|enum\\)")
      vim.fn.match
          .returns(-1)
          .on_call_with("use Namespace\\Class2;", "^\\(class\\|final\\|interface\\|abstract\\|trait\\|enum\\)")
      vim.fn.match
          .returns(0)
          .on_call_with("class TestClass {", "^\\(class\\|final\\|interface\\|abstract\\|trait\\|enum\\)")

      local result = namespace.get_namespaces()

      assert.same({
        { name = "Class1", ns = "Namespace\\Class1" },
        { name = "Class2", ns = "Namespace\\Class2" },
      }, result)
    end)

    it("should handle multiple namespace segments", function()
      api.nvim_buf_get_lines.returns({
        "<?php",
        "",
        "use Namespace\\Subnamespace\\Class1;",
        "use AnotherNamespace\\Class2;",
        "class TestClass {",
        "}",
      })
      vim.fn.match
          .returns(-1)
          .on_call_with("use Namespace\\Subnamespace\\Class1;",
            "^\\(class\\|final\\|interface\\|abstract\\|trait\\|enum\\)")
      vim.fn.match
          .returns(-1)
          .on_call_with("use AnotherNamespace\\Class2;", "^\\(class\\|final\\|interface\\|abstract\\|trait\\|enum\\)")
      vim.fn.match
          .returns(0)
          .on_call_with("class TestClass {", "^\\(class\\|final\\|interface\\|abstract\\|trait\\|enum\\)")

      local result = namespace.get_namespaces()

      assert.same({
        { name = "Class1", ns = "Namespace\\Subnamespace\\Class1" },
        { name = "Class2", ns = "AnotherNamespace\\Class2" },
      }, result)
    end)

    it("should stop at interface declaration", function()
      api.nvim_buf_get_lines.returns({
        "<?php",
        "",
        "use Namespace\\Class1;",
        "interface TestInterface {",
        "}",
      })
      vim.fn.match
          .returns(-1)
          .on_call_with("use Namespace\\Class1;", "^\\(class\\|final\\|interface\\|abstract\\|trait\\|enum\\)")
      vim.fn.match
          .returns(0)
          .on_call_with("interface TestInterface {", "^\\(class\\|final\\|interface\\|abstract\\|trait\\|enum\\)")

      local result = namespace.get_namespaces()

      assert.same({
        { name = "Class1", ns = "Namespace\\Class1" },
      }, result)
    end)
  end)
end)
