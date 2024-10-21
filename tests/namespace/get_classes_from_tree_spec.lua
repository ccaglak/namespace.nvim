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
        StaticClass::test();
        EnumClass::test;
        $obj = new SomeClass();
        if ($result instanceof AnotherClass){}
        }
        use WeakMap;
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
      { name = "EnumClass" },
      { name = "WeakMap" },
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
  it("should handle multiple classes in a single file", function()
    local mock_buf = 0
    local mock_content = [[
      <?php
      class Class1 {}
      class Class2 extends Class1 {}
      class Class3 implements Interface1, Interface2 {}
    ]]
    vim.api.nvim_buf_set_lines(mock_buf, 0, -1, false, vim.split(mock_content, "\n"))
    local result = main.get_classes_from_tree(mock_buf)
    assert.True(eq({
      { name = "Class1" },
      { name = "Interface1" },
      { name = "Interface2" },
    }, result))
  end)
  it("should handle class names with namespaces", function()
    local mock_buf = 0
    local mock_content = [[
      <?php
      namespace App\Models;
      use Illuminate\Database\Eloquent\Model;
      class User extends Model {}
    ]]
    vim.api.nvim_buf_set_lines(mock_buf, 0, -1, false, vim.split(mock_content, "\n"))
    local result = main.get_classes_from_tree(mock_buf)
    assert.True(eq({
      { name = "Model" },
    }, result))
  end)
  it("should handle anonymous classes", function()
    local mock_buf = 0
    local mock_content = [[
      <?php
      $obj = new class extends BaseClass implements SomeInterface {};
    ]]
    vim.api.nvim_buf_set_lines(mock_buf, 0, -1, false, vim.split(mock_content, "\n"))
    local result = main.get_classes_from_tree(mock_buf)
    assert.True(eq({
      { name = "BaseClass" },
      { name = "SomeInterface" },
    }, result))
  end)
  it("should handle nested classes should return empty", function()
    local mock_buf = 0
    local mock_content = [[
      <?php
      class OuterClass {
        public function someMethod() {
          class InnerClass {}
        }
      }
    ]]
    vim.api.nvim_buf_set_lines(mock_buf, 0, -1, false, vim.split(mock_content, "\n"))
    local result = main.get_classes_from_tree(mock_buf)
    assert.True(eq({}, result))
  end)
end)
