local namespace = require("namespace.mainTest")
local mock = require("luassert.mock")
local stub = require("luassert.stub")
local ts = mock(require("nvim-treesitter"), true)
local api = mock(vim.api, true)

describe("mainTest", function()
  describe("get_classes_from_tree", function()
    local bufnr = 1
    local fake_root = {}
    local fake_tree = {
      root = function()
        return fake_root
      end,
    }
    local fake_syntax_tree = { [1] = fake_tree }
    local fake_language_tree = {
      parse = function()
        return fake_syntax_tree
      end,
    }

    before_each(function()
      stub(ts, "get_parser")
      stub(namespace, "get_cached_query")
      stub(ts, "get_node_text")
      api.nvim_get_current_buf = stub.new(function()
        return bufnr
      end)
    end)

    after_each(function()
      ts.get_parser:revert()
      namespace.get_cached_query:revert()
      ts.get_node_text:revert()
      mock.revert(api)
    end)

    it("should return nil if language_tree is nil", function()
      ts.get_parser.returns(nil)
      local result = namespace.get_classes_from_tree()
      assert.is_nil(result)
    end)

    it("should use the provided bufnr", function()
      ts.get_parser.returns(fake_language_tree)
      namespace.get_cached_query.returns({
        iter_captures = function()
          return {}
        end,
      })
      namespace.get_classes_from_tree(2)
      assert.stub(ts.get_parser).was_called_with(2, "php")
    end)

    it("should use the current buffer if no bufnr is provided", function()
      ts.get_parser.returns(fake_language_tree)
      namespace.get_cached_query.returns({
        iter_captures = function()
          return {}
        end,
      })
      namespace.get_classes_from_tree()
      assert.stub(ts.get_parser).was_called_with(bufnr, "php")
    end)

    it("should return an empty table if no declarations are found", function()
      ts.get_parser.returns(fake_language_tree)
      namespace.get_cached_query.returns({
        iter_captures = function()
          return {}
        end,
      })
      local result = namespace.get_classes_from_tree()
      assert.same({}, result)
    end)

    it("should return declarations with correct structure", function()
      ts.get_parser.returns(fake_language_tree)
      local fake_node = {}
      namespace.get_cached_query.returns({
        iter_captures = function()
          return coroutine.wrap(function()
            coroutine.yield(fake_node, "att")
          end)
        end,
      })
      ts.get_node_text.returns("TestClass")

      local result = namespace.get_classes_from_tree()

      assert.same({ { name = "TestClass" } }, result)
      assert.stub(ts.get_node_text).was_called_with(fake_node, bufnr)
    end)

    it("should handle multiple declarations", function()
      ts.get_parser.returns(fake_language_tree)
      local fake_node1, fake_node2 = {}, {}
      namespace.get_cached_query.returns({
        iter_captures = function()
          return coroutine.wrap(function()
            coroutine.yield(fake_node1, "att")
            coroutine.yield(fake_node2, "sce")
          end)
        end,
      })
      ts.get_node_text.on_call_with(fake_node1, bufnr).returns("Class1")
      ts.get_node_text.on_call_with(fake_node2, bufnr).returns("Class2")

      local result = namespace.get_classes_from_tree()

      assert.same({ { name = "Class1" }, { name = "Class2" } }, result)
    end)
  end)
end)
