local namespace = require("tests.namespace.mainTest")
local mock = require("luassert.mock")
local stub = require("luassert.stub")

describe("mainTest", function()
  describe("search_autoload_classmap", function()
    local original_system
    local original_sep

    before_each(function()
      original_system = vim.fn.system
      vim.fn.system = stub.new(vim.fn, "system")
      original_sep = package.config:sub(1, 1)
      package.config = "/"
      stub(namespace, "get_project_root")
    end)

    after_each(function()
      vim.fn.system = original_system
      package.config = original_sep
      namespace.get_project_root:revert()
    end)

    it("should handle single class search", function()
      namespace.get_project_root.returns("/home/runner/work/namespace.nvim/vendor")

      -- namespace.get_project_root.returns("/home/user/project")
      vim.fn.system.returns("'Namespace\\Class' => $baseDir . '/src/Class.php'")

      local result = namespace.search_autoload_classmap({ { name = "Class" } })

      assert.are.same({ Class = { { fqcn = "Namespace\\Class", path = "/src/Class.php" } } }, result)
      assert
        .stub(vim.fn.system)
        .was_called_with("rg '/Class.php' /home/runner/work/namespace.nvim/namespace.nvim/vendor/composer/autoload_classmap.php")
    end)

    it("should handle classes with no matches", function()
      namespace.get_project_root.returns("/home/user/project")
      vim.fn.system.returns("")

      local result = namespace.search_autoload_classmap({ { name = "NonExistentClass" } })

      assert.same({ NonExistentClass = {} }, result)
    end)

    it("should handle multiple matches for a single class", function()
      namespace.get_project_root.returns("/home/user/project")
      vim.fn.system.returns([[
'Namespace\Class' => $baseDir . '/src/Class.php'
'AnotherNamespace\Class' => $baseDir . '/vendor/package/src/Class.php'
      ]])

      local result = namespace.search_autoload_classmap({ { name = "Class" } })

      assert.same({
        Class = {
          { fqcn = "Namespace\\Class", path = "/src/Class.php" },
          { fqcn = "AnotherNamespace\\Class", path = "/vendor/package/src/Class.php" },
        },
      }, result)
    end)

    it("should handle malformed lines in autoload_classmap.php", function()
      namespace.get_project_root.returns("/home/user/project")
      vim.fn.system.returns([[
'Namespace\Class' => $baseDir . '/src/Class.php'
malformed line
'AnotherNamespace\Class' => $baseDir . '/vendor/package/src/Class.php'
      ]])

      local result = namespace.search_autoload_classmap({ { name = "Class" } })

      assert.same({
        Class = {
          { fqcn = "Namespace\\Class", path = "/src/Class.php" },
          { fqcn = "AnotherNamespace\\Class", path = "/vendor/package/src/Class.php" },
        },
      }, result)
    end)
  end)
end)
