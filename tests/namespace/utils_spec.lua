local utils = require("namespace.utils")

describe("utils", function()
  describe("table.contains2", function()
    it("should return true when value is found in nested table", function()
      local t = { { a = 1, b = 2 }, { c = 3, d = 4 } }
      assert.is_true(table.contains2(t, 2))
      assert.is_true(table.contains2(t, 3))
    end)

    it("should return false when value is not found in nested table", function()
      local t = { { a = 1, b = 2 }, { c = 3, d = 4 } }
      assert.is_false(table.contains2(t, 5))
    end)

    it("should handle empty table", function()
      local t = {}
      assert.is_false(table.contains2(t, 1))
    end)

    it("should handle table with empty nested tables", function()
      local t = { {}, {} }
      assert.is_false(table.contains2(t, 1))
    end)
  end)

  describe("table.remove_duplicates", function()
    it("should remove duplicate entries based on name", function()
      local input = {
        { name = "a", value = 1 },
        { name = "b", value = 2 },
        { name = "a", value = 3 },
        { name = "c", value = 4 }
      }
      local expected = {
        { name = "a", value = 1 },
        { name = "b", value = 2 },
        { name = "c", value = 4 }
      }
      assert.same(expected, table.remove_duplicates(input))
    end)

    it("should handle empty table", function()
      assert.same({}, table.remove_duplicates({}))
    end)

    it("should handle table with no duplicates", function()
      local input = {
        { name = "a", value = 1 },
        { name = "b", value = 2 },
        { name = "c", value = 3 }
      }
      assert.same(input, table.remove_duplicates(input))
    end)

    it("should keep the first occurrence of duplicate entries", function()
      local input = {
        { name = "a", value = 1 },
        { name = "a", value = 2 },
        { name = "b", value = 3 },
        { name = "a", value = 4 }
      }
      local expected = {
        { name = "a", value = 1 },
        { name = "b", value = 3 }
      }
      assert.same(expected, table.remove_duplicates(input))
    end)
  end)
end)
