local assert = require("luassert")
local main = require("tests.namespace.mainTest")
local mock = require("luassert.mock")
local stub = require("luassert.stub")

describe("M.search_autoload_classmap", function()
  it("should return an empty table when no classes are provided", function()
    local result = main.search_autoload_classmap({})
    assert.are.same({}, result)
  end)

  it("should return an empty table when no matches are found", function()
    stub(vim.fn, "system")
    vim.fn.system.returns("")
    local result = main.search_autoload_classmap({ { name = "NonExistentClass" } })
    assert.are.same({ NonExistentClass = {} }, result)
    vim.fn.system:revert()
  end)

  it("should return a table with a single match when one match is found", function()
    stub(vim.fn, "system")
    vim.fn.system.returns("'Namespace\\Class' => $baseDir . '/src/Class.php'")
    local result = main.search_autoload_classmap({ { name = "Class" } })
    assert.are.same({ Class = { { fqcn = "Namespace\\Class", path = "/src/Class.php" } } }, result)
    vim.fn.system:revert()
  end)

  it("should return a table with multiple matches when multiple matches are found", function()
    stub(vim.fn, "system")
    vim.fn.system.returns([[
'Namespace\Class' => $baseDir . '/src/Class.php'
'AnotherNamespace\Class' => $baseDir . '/vendor/package/src/Class.php'
    ]])
    local result = main.search_autoload_classmap({ { name = "Class" } })
    assert.are.same({
      Class = {
        { fqcn = "Namespace\\Class", path = "/src/Class.php" },
        { fqcn = "AnotherNamespace\\Class", path = "/vendor/package/src/Class.php" },
      },
    }, result)
    vim.fn.system:revert()
  end)

  it("should handle malformed lines in the output", function()
    stub(vim.fn, "system")
    vim.fn.system.returns([[
'Namespace\Class' => $baseDir . '/src/Class.php'
malformed line
'AnotherNamespace\Class' => $baseDir . '/vendor/package/src/Class.php'
    ]])
    local result = main.search_autoload_classmap({ { name = "Class" } })
    assert.are.same({
      Class = {
        { fqcn = "Namespace\\Class", path = "/src/Class.php" },
        { fqcn = "AnotherNamespace\\Class", path = "/vendor/package/src/Class.php" },
      },
    }, result)
    vim.fn.system:revert()
  end)
end)
