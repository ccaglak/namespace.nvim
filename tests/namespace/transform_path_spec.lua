local namespace = require("namespace.mainTest")
local mock = require("luassert.mock")

describe("mainTest", function()
  describe("transform_path", function()
    local workspace_root = "/home/user/project"
    local prefix_table = {
      { src = "src", prefix = "App\\" },
      { src = "tests", prefix = "Tests\\" },
    }

    it("should return nil for nil input", function()
      local result = namespace.transform_path(nil, prefix_table, workspace_root, false)
      assert.is_nil(result)
    end)

    it("should transform path without composer", function()
      local path = "/home/user/project/src/Controller/UserController.php"
      local expected = "use App\\Controller\\UserController;"
      local result = namespace.transform_path(path, prefix_table, workspace_root, false)
      assert.are.equal(expected, result)
    end)

    it("should transform path with composer", function()
      local path = "/home/user/project/src/Controller/UserController.php"
      local expected = "use src\\Controller\\UserController;"
      local result = namespace.transform_path(path, prefix_table, workspace_root, true)
      assert.are.equal(expected, result)
    end)

    it("should handle paths with backslashes", function()
      local path = "C:\\Users\\user\\project\\src\\Model\\User.php"
      local expected = "use App\\Model\\User;"
      local result = namespace.transform_path(path, prefix_table, "C:\\Users\\user\\project", false)
      assert.are.equal(expected, result)
    end)

    it("should handle paths without matching prefix", function()
      local path = "/home/user/project/lib/Helper/StringHelper.php"
      local expected = "use lib\\Helper\\StringHelper;"
      local result = namespace.transform_path(path, prefix_table, workspace_root, false)
      assert.are.equal(expected, result)
    end)

    it("should handle paths with multiple segments matching prefix", function()
      local path = "/home/user/project/tests/Unit/Controller/UserControllerTest.php"
      local expected = "use Tests\\Unit\\Controller\\UserControllerTest;"
      local result = namespace.transform_path(path, prefix_table, workspace_root, false)
      assert.are.equal(expected, result)
    end)
  end)
end)
