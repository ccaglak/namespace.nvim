local assert = require("luassert")
local main = require("tests.namespace.mainTest")

local function eq(tbl1, tbl2)
  if #tbl1 ~= #tbl2 then
    return false
  end
  local lookup = {}
  for _, k in ipairs(tbl2) do
    lookup[k.name] = true
  end
  for _, k in ipairs(tbl1) do
    if not lookup[k.name] then
      return false
    end
  end
  return true
end

describe("M.get_classes_from_tree()", function()
  it("should return a table of class declarations", function()
    -- Mock the necessary vim functions and API calls
    local mock_buf = 1
    local mock_content = [[
      <?php

      #[Attribute]
      class TestClass extends ExtendsClass implements TestInterface  {
      use TestTrait;
      public function add(ParamClass $param){
        (new ScopedClass())->add();
        StaticClass::add();
        $obj = new SomeClass();
        if ($result instanceof AnotherClass){}
        }
      }
    ]]

    -- Set up the mock buffer content
    vim.api.nvim_buf_set_lines(mock_buf, 0, -1, false, vim.split(mock_content, "\n"))

    -- Call the function
    local result = main.get_classes_from_tree(mock_buf)

    -- Assert the results
    assert.is_table(result)
    assert.True(eq({
      { name = "TestInterface" },
      { name = "TestTrait" },
      { name = "SomeClass" },
      { name = "AnotherClass" },
      { name = "ExtendsClass" },
      { name = "ParamClass" },
      { name = "ScopedClass" },
      { name = "StaticClass" },
      { name = "Attribute" },
    }, result))
  end)

  it("should handle empty files", function()
    local mock_buf = 0
    vim.api.nvim_buf_set_lines(mock_buf, 0, -1, false, {})

    local result = main.get_classes_from_tree(mock_buf)

    assert.is_table(result)
    assert.are.same({}, result)
  end)

  it("should handle files with no class declarations", function()
    local mock_buf = 0
    local mock_content = [[
      <?php
      $a = 1;
      $b = 2;
      echo $a + $b;
    ]]

    vim.api.nvim_buf_set_lines(mock_buf, 0, -1, false, vim.split(mock_content, "\n"))

    local result = main.get_classes_from_tree(mock_buf)

    assert.is_table(result)
    assert.are.same({}, result)
  end)
end)
