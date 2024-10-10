local namespace = require("namespace.composer")
local mock = require("luassert.mock")
local stub = require("luassert.stub")

describe("composer", function()
  describe("resolve_namespace", function()
    local original_expand

    before_each(function()
      original_expand = vim.fn.expand
      vim.fn.expand = stub.new(vim.fn, "expand")
      stub(namespace, "read_composer_file")
      stub(namespace, "get_prefix_and_src")
    end)

    after_each(function()
      vim.fn.expand = original_expand
      namespace.read_composer_file:revert()
      namespace.get_prefix_and_src:revert()
    end)

    it("should return nil when composer data is not available", function()
      namespace.read_composer_file.returns(nil)

      local result = namespace.resolve_namespace()

      assert.is_nil(result)
      assert.stub(namespace.read_composer_file).was_called()
      assert.stub(namespace.get_prefix_and_src).was_not_called()
    end)

    it("should return nil when prefix_and_src is nil", function()
      namespace.read_composer_file.returns({})
      namespace.get_prefix_and_src.returns(nil)
      vim.fn.expand.returns("/path/to/current/file")

      local result = namespace.resolve_namespace()

      assert.is_nil(result)
      assert.stub(namespace.read_composer_file).was_called()
      assert.stub(namespace.get_prefix_and_src).was_called()
    end)

    it("should return nil when no matching src is found", function()
      namespace.read_composer_file.returns({})
      namespace.get_prefix_and_src.returns({
        { src = "src", prefix = "App\\" },
      })
      vim.fn.expand.returns("/project/root/tests/Unit")

      _G.root = "/project/root"
      _G.sep = "/"

      local result = namespace.resolve_namespace()

      assert.is_nil(result)
      assert.stub(namespace.read_composer_file).was_called()
      assert.stub(namespace.get_prefix_and_src).was_called()
      assert.stub(vim.fn.expand).was_called_with("%:h")
    end)
  end)
end)

describe("composer", function()
  describe("read_composer_file", function()
    local original_findfile
    local original_readfile
    local original_json_decode

    before_each(function()
      original_findfile = vim.fn.findfile
      original_readfile = vim.fn.readfile
      original_json_decode = vim.json.decode

      vim.fn.findfile = stub.new(vim.fn, "findfile")
      vim.fn.readfile = stub.new(vim.fn, "readfile")
      vim.json.decode = stub.new(vim.json, "decode")

      namespace.cache = {}
    end)

    after_each(function()
      vim.fn.findfile = original_findfile
      vim.fn.readfile = original_readfile
      vim.json.decode = original_json_decode
    end)

    it("should return nil if composer.json is not found", function()
      vim.fn.findfile.returns("")
      local result = namespace.read_composer_file()
      assert.is_nil(result)
      assert.stub(vim.fn.findfile).was_called_with("composer.json", ".;")
    end)

    it("should read and parse composer.json if found", function()
      vim.fn.findfile.returns("/path/to/composer.json")
      vim.fn.readfile.returns({ '{"name": "test-project"}' })
      vim.json.decode.returns({ name = "test-project" })

      local result = namespace.read_composer_file()

      assert.are.same({ name = "test-project" }, result)
      assert.stub(vim.fn.findfile).was_called_with("composer.json", ".;")
      assert.stub(vim.fn.readfile).was_called_with("/path/to/composer.json")
      assert.stub(vim.json.decode).was_called_with('{"name": "test-project"}')
    end)
  end)
end)

describe("composer", function()
  describe("get_prefix_and_src", function()
    local original_read_composer_file

    before_each(function()
      original_read_composer_file = namespace.read_composer_file
      stub(namespace, "read_composer_file")
    end)

    after_each(function()
      namespace.read_composer_file = original_read_composer_file
    end)

    it("should return nil when composer data is nil", function()
      namespace.read_composer_file.returns(nil)
      local result = namespace.get_prefix_and_src()
      assert.is_nil(result)
    end)

    it("should return nil when autoload is nil", function()
      namespace.read_composer_file.returns({})
      local result = namespace.get_prefix_and_src()
      assert.is_nil(result)
    end)

    it("should return psr-4 data from autoload", function()
      namespace.read_composer_file.returns({
        autoload = {
          ["psr-4"] = {
            ["App\\"] = "app/",
          },
        },
      })
      local result = namespace.get_prefix_and_src()
      assert.are.same({ { prefix = "App\\", src = "app/" } }, result)
    end)

    it("should return psr-4 data from autoload-dev", function()
      namespace.read_composer_file.returns({
        autoload = {
          ["psr-4"] = {
            ["App\\"] = "app/",
          },
        },
        ["autoload-dev"] = {
          ["psr-4"] = {
            ["Tests\\"] = "tests/",
          },
        },
      })
      local result = namespace.get_prefix_and_src()
      assert.are.same({ { prefix = "App\\", src = "app/" }, { prefix = "Tests\\", src = "tests/" } }, result)
    end)

    it("should return combined psr-4 data from autoload and autoload-dev", function()
      namespace.read_composer_file.returns({
        autoload = {
          ["psr-4"] = {
            ["App\\"] = "app/",
          },
        },
        ["autoload-dev"] = {
          ["psr-4"] = {
            ["Tests\\"] = "tests/",
          },
        },
      })
      local result = namespace.get_prefix_and_src()
      assert.are.same({
        { prefix = "App\\",   src = "app/" },
        { prefix = "Tests\\", src = "tests/" },
      }, result)
    end)

    it("should handle multiple psr-4 entries", function()
      namespace.read_composer_file.returns({
        autoload = {
          ["psr-4"] = {
            ["App\\"] = "app/",
            ["Core\\"] = "core/",
          },
        },
      })
      local result = namespace.get_prefix_and_src()
      assert.are.same({
        { prefix = "App\\",  src = "app/" },
        { prefix = "Core\\", src = "core/" },
      }, result)
    end)

    it("should return an empty table when no psr-4 data is present", function()
      namespace.read_composer_file.returns({
        autoload = {},
      })
      local result = namespace.get_prefix_and_src()
      assert.are.same({}, result)
    end)
  end)
end)
describe("composer", function()
  describe("get_insertion_point", function()
    local original_nvim_buf_get_lines

    before_each(function()
      original_nvim_buf_get_lines = vim.api.nvim_buf_get_lines
      vim.api.nvim_buf_get_lines = stub.new(vim.api, "nvim_buf_get_lines")
    end)

    after_each(function()
      vim.api.nvim_buf_get_lines = original_nvim_buf_get_lines
    end)

    it("should return insertion point before namespace", function()
      vim.api.nvim_buf_get_lines.returns({
        "<?php",
        "",
        "namespace App\\Test;",
        "",
        "class TestClass",
        "{",
        "}"
      })

      local line, col = namespace.get_insertion_point()

      assert.are.equal(3, line)
      assert.are.equal(1, col)
    end)

    it("should return insertion point before class when no namespace is present", function()
      vim.api.nvim_buf_get_lines.returns({
        "<?php",
        "",
        "class TestClass",
        "{",
        "}"
      })

      local line, col = namespace.get_insertion_point()

      assert.are.equal(2, line)
      assert.is_nil(col)
    end)

    it("should return insertion point after declare statement", function()
      vim.api.nvim_buf_get_lines.returns({
        "<?php",
        "",
        "declare(strict_types=1);",
        "",
        "namespace App\\Test;",
        "",
        "class TestClass",
        "{",
        "}"
      })

      local line, col = namespace.get_insertion_point()

      assert.are.equal(5, line)
      assert.are.equal(1, col)
    end)

    it("should return insertion point before interface", function()
      vim.api.nvim_buf_get_lines.returns({
        "<?php",
        "",
        "interface TestInterface",
        "{",
        "}"
      })

      local line, col = namespace.get_insertion_point()

      assert.are.equal(2, line)
      assert.is_nil(col)
    end)

    it("should return insertion point before abstract class", function()
      vim.api.nvim_buf_get_lines.returns({
        "<?php",
        "",
        "abstract class AbstractTest",
        "{",
        "}"
      })

      local line, col = namespace.get_insertion_point()

      assert.are.equal(2, line)
      assert.is_nil(col)
    end)

    it("should return insertion point before trait", function()
      vim.api.nvim_buf_get_lines.returns({
        "<?php",
        "",
        "trait TestTrait",
        "{",
        "}"
      })

      local line, col = namespace.get_insertion_point()

      assert.are.equal(2, line)
      assert.is_nil(col)
    end)

    it("should return insertion point before enum", function()
      vim.api.nvim_buf_get_lines.returns({
        "<?php",
        "",
        "enum TestEnum",
        "{",
        "}"
      })

      local line, col = namespace.get_insertion_point()

      assert.are.equal(2, line)
      assert.is_nil(col)
    end)

    it("should return nil when file is empty", function()
      vim.api.nvim_buf_get_lines.returns({})

      local line, col = namespace.get_insertion_point()

      assert.is_nil(line)
      assert.is_nil(col)
    end)

    it("should return insertion point before final class", function()
      vim.api.nvim_buf_get_lines.returns({
        "<?php",
        "",
        "final class FinalTest",
        "{",
        "}"
      })

      local line, col = namespace.get_insertion_point()

      assert.are.equal(2, line)
      assert.is_nil(col)
    end)
  end)
end)
