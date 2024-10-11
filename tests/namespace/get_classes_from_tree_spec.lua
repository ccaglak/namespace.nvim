local namespace = require("namespace.mainTest")
local mock = require("luassert.mock")
local stub = require("luassert.stub")
local api = mock(vim.api, true)
local ts = mock(vim.treesitter, true)

describe("mainTest", function()
  describe("get_classes_from_tree", function()
    local original_get_parser
    local original_parse
    local original_root
    local original_iter_captures
    local original_get_node_text

    before_each(function()
      original_get_parser = ts.get_parser
      original_parse = stub.new()
      original_root = stub.new()
      original_iter_captures = stub.new()
      original_get_node_text = ts.get_node_text

      ts.get_parser = stub.new().returns({
        parse = original_parse
      })
      original_parse.returns({ {
        root = original_root
      } })
      stub(namespace, "get_cached_query")
      namespace.get_cached_query.returns({
        iter_captures = original_iter_captures
      })
      ts.get_node_text = stub.new()
    end)

    after_each(function()
      ts.get_parser = original_get_parser
      ts.get_node_text = original_get_node_text
      namespace.get_cached_query:revert()
      mock.revert(api)
      mock.revert(ts)
    end)

    it("should return nil when language_tree is nil", function()
      ts.get_parser.returns(nil)
      local result = namespace.get_classes_from_tree()
      assert.is_nil(result)
    end)

    it("should return empty table when no captures are found", function()
      original_iter_captures.returns(function() return nil end)
      local result = namespace.get_classes_from_tree()
      assert.are.same({}, result)
    end)

    it("should return table with captured names", function()
      local captures = {
        { ts.new_node(), "TestClass" },
        { ts.new_node(), "AnotherClass" }
      }
      original_iter_captures.returns(function() return next, captures end)
      ts.get_node_text.returns("TestClass").on_call_with(captures[1][1])
      ts.get_node_text.returns("AnotherClass").on_call_with(captures[2][1])

      local result = namespace.get_classes_from_tree()
      assert.are.same({
        { name = "TestClass" },
        { name = "AnotherClass" }
      }, result)
    end)

    it("should use provided buffer number", function()
      local bufnr = 10
      namespace.get_classes_from_tree(bufnr)
      assert.stub(ts.get_parser).was_called_with(bufnr, "php")
    end)

    it("should use current buffer when no buffer number is provided", function()
      api.nvim_get_current_buf.returns(5)
      namespace.get_classes_from_tree()
      assert.stub(ts.get_parser).was_called_with(5, "php")
    end)
  end)
end)
