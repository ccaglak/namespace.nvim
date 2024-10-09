local namespace = require("namespace.mainTest")
local mock = require("luassert.mock")
local stub = require("luassert.stub")
local ts = mock(require("nvim-treesitter"), true)
local api = mock(vim.api, true)

describe("mainTest", function()
  describe("async_search_files", function()
    local original_system
    local original_schedule

    before_each(function()
      original_system = vim.system
      original_schedule = vim.schedule
      vim.system = stub.new()
      vim.schedule = stub.new()
      namespace.cache = { file_search_results = {} }
    end)

    after_each(function()
      vim.system = original_system
      vim.schedule = original_schedule
    end)

    it("should return cached results if available", function()
      local pattern = "*.php"
      local cached_results = { "file1.php", "file2.php" }
      namespace.cache.file_search_results[pattern] = cached_results
      local callback = stub.new()

      namespace.async_search_files(pattern, callback)

      assert.stub(callback).was_called_with(cached_results)
      assert.stub(vim.system).was_not_called()
    end)

    it("should execute rg command with correct arguments", function()
      local pattern = "*.php"
      local callback = stub.new()

      namespace.async_search_files(pattern, callback)

      assert.stub(vim.system).was_called()
      local call_args = vim.system.calls[1]
      assert.are.same("rg", call_args[1][1])
      assert.are.same("--files", call_args[1][2])
      assert.are.same("--glob", call_args[1][3])
      assert.are.same(pattern, call_args[1][4])
    end)

    it("should handle empty results", function()
      local pattern = "*.nonexistent"
      local callback = stub.new()

      vim.system.invokes(function(cmd, opts, cb)
        cb({ code = 0, stdout = "" })
      end)

      namespace.async_search_files(pattern, callback)

      assert.stub(vim.schedule).was_called()
      local schedule_call = vim.schedule.calls[1]
      schedule_call[1]()
      assert.stub(callback).was_called_with({})
    end)

    it("should handle non-zero exit code", function()
      local pattern = "*.php"
      local callback = stub.new()

      vim.system.invokes(function(cmd, opts, cb)
        cb({ code = 1, stdout = "" })
      end)

      namespace.async_search_files(pattern, callback)

      assert.stub(vim.schedule).was_called()
      local schedule_call = vim.schedule.calls[1]
      schedule_call[1]()
      assert.stub(callback).was_called_with({})
    end)

    it("should parse and return multiple results", function()
      local pattern = "*.lua"
      local callback = stub.new()
      local mock_stdout = "file1.lua\nfile2.lua\nfile3.lua"

      vim.system.invokes(function(cmd, opts, cb)
        cb({ code = 0, stdout = mock_stdout })
      end)

      namespace.async_search_files(pattern, callback)

      assert.stub(vim.schedule).was_called()
      local schedule_call = vim.schedule.calls[1]
      schedule_call[1]()
      assert.stub(callback).was_called_with({ "file1.lua", "file2.lua", "file3.lua" })
    end)

    it("should cache results after successful search", function()
      local pattern = "*.js"
      local callback = stub.new()
      local mock_results = { "script1.js", "script2.js" }

      vim.system.invokes(function(cmd, opts, cb)
        cb({ code = 0, stdout = table.concat(mock_results, "\n") })
      end)

      namespace.async_search_files(pattern, callback)

      assert.stub(vim.schedule).was_called()
      local schedule_call = vim.schedule.calls[1]
      schedule_call[1]()
      assert.are.same(mock_results, namespace.cache.file_search_results[pattern])
    end)
  end)
end)
