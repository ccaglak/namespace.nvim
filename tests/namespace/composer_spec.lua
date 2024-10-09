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
        { prefix = "App\\", src = "app/" },
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
        { prefix = "App\\", src = "app/" },
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

    it("should return the line number and position of 'namespace' when found", function()
      vim.api.nvim_buf_get_lines.returns({
        "<?php",
        "",
        "namespace App\\Controller;",
        "",
        "class UserController",
      })

      local line, pos = namespace.get_insertion_point()

      assert.equals(3, line)
      assert.equals(1, pos)
    end)

    it("should return the line number after 'declare' statements for class/interface/trait", function()
      vim.api.nvim_buf_get_lines.returns({
        "<?php",
        "",
        "declare(strict_types=1);",
        "",
        "class UserController",
      })

      local line = namespace.get_insertion_point()

      assert.equals(3, line)
    end)

    it("should return nil when no relevant statements are found", function()
      vim.api.nvim_buf_get_lines.returns({
        "<?php",
        "",
        "// Some comments",
        "function helper() {",
        "    // ...",
        "}",
      })

      local line, pos = namespace.get_insertion_point()

      assert.is_nil(line)
      assert.is_nil(pos)
    end)

    it("should handle multiple declare statements", function()
      vim.api.nvim_buf_get_lines.returns({
        "<?php",
        "",
        "declare(strict_types=1);",
        "declare(ticks=1);",
        "",
        "final class UserController",
      })

      local line = namespace.get_insertion_point()

      assert.equals(4, line)
    end)

    it("should return the correct line for abstract class declaration", function()
      vim.api.nvim_buf_get_lines.returns({
        "<?php",
        "",
        "declare(strict_types=1);",
        "",
        "abstract class BaseController",
      })

      local line = namespace.get_insertion_point()

      assert.equals(3, line)
    end)

    it("should return the correct line for interface declaration", function()
      vim.api.nvim_buf_get_lines.returns({
        "<?php",
        "",
        "interface UserRepositoryInterface",
      })

      local line = namespace.get_insertion_point()

      assert.is_nil(line)
    end)

    it("should return the correct line for trait declaration", function()
      vim.api.nvim_buf_get_lines.returns({
        "<?php",
        "",
        "trait LoggableTrait",
      })

      local line = namespace.get_insertion_point()

      assert.is_nil(line)
    end)

    it("should return the correct line for enum declaration", function()
      vim.api.nvim_buf_get_lines.returns({
        "<?php",
        "",
        "enum UserStatus",
      })

      local line = namespace.get_insertion_point()

      assert.is_nil(line)
    end)
  end)
end)
