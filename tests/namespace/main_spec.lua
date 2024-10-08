describe("get_classes_from_tree", function()
  local main = require("namespace.main")
  local mock_bufnr = 1

  local function setup_mock_buffer(content)
    vim.api.nvim_create_buf = function()
      return mock_bufnr
    end
    vim.api.nvim_buf_set_lines = function() end
    _G.vim.treesitter.get_parser = function()
      return {
        parse = function()
          return { {
            root = function()
              return {}
            end,
          } }
        end,
      }
    end
  end

  it("should return an empty table for an empty file", function()
    setup_mock_buffer("")
    _G.vim.treesitter.query.parse = function()
      return {
        iter_captures = function()
          return function()
            return nil
          end
        end,
      }
    end
    local result = main.get_classes_from_tree(mock_bufnr)
    assert.same({}, result)
  end)

  it("should return correct classes for a PHP file with multiple declarations", function()
    setup_mock_buffer([[
            <?php
            class TestClass {}
            interface TestInterface {}
            trait TestTrait {}
        ]])

    _G.vim.treesitter.query.parse = function()
      return {
        iter_captures = function()
          return coroutine.wrap(function()
            coroutine.yield(nil, "TestClass", nil)
            coroutine.yield(nil, "TestInterface", nil)
            coroutine.yield(nil, "TestTrait", nil)
          end)
        end,
      }
    end

    local result = main.get_classes_from_tree(mock_bufnr)
    assert.same({
      { name = "TestClass" },
      { name = "TestInterface" },
      { name = "TestTrait" },
    }, result)
  end)

  it("should handle attribute declarations", function()
    setup_mock_buffer([[
            <?php
            #[Attribute]
            class TestAttribute {}
        ]])

    _G.vim.treesitter.query.parse = function()
      return {
        iter_captures = function()
          return coroutine.wrap(function()
            coroutine.yield(nil, "Attribute", nil)
            coroutine.yield(nil, "TestAttribute", nil)
          end)
        end,
      }
    end

    local result = main.get_classes_from_tree(mock_bufnr)
    assert.same({
      { name = "Attribute" },
      { name = "TestAttribute" },
    }, result)
  end)
end)
