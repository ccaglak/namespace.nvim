local assert = require("luassert")
local main = require("tests.namespace.mainTest")
local mock = require("luassert.mock")
local stub = require("luassert.stub")

describe("M.get_insertion_point()", function()
  local original_nvim_buf_get_lines

  before_each(function()
    original_nvim_buf_get_lines = vim.api.nvim_buf_get_lines
    vim.api.nvim_buf_get_lines = stub.new(vim.api, "nvim_buf_get_lines")
  end)

  after_each(function()
    vim.api.nvim_buf_get_lines = original_nvim_buf_get_lines
  end)

  it("should return nil for empty file", function()
    vim.api.nvim_buf_get_lines.returns({})
    local result = main.get_insertion_point()
    assert.is_nil(result)
  end)

  it("should return 2 for file with only PHP opening tag", function()
    vim.api.nvim_buf_get_lines.returns({ "<?php" })
    local result = main.get_insertion_point()
    assert.are.equal(2, result)
  end)

  it("should return correct insertion point after declare statement", function()
    vim.api.nvim_buf_get_lines.returns({
      "<?php",
      "declare(strict_types=1);",
      "class TestClass {}",
    })
    local result = main.get_insertion_point()
    assert.are.equal(2, result)
  end)

  it("should return correct insertion point after namespace statement", function()
    vim.api.nvim_buf_get_lines.returns({
      "<?php",
      "namespace App\\Test;",
      "class TestClass {}",
    })
    local result = main.get_insertion_point()
    assert.are.equal(2, result)
  end)

  it("should return correct insertion point after use statements", function()
    vim.api.nvim_buf_get_lines.returns({
      "<?php",
      "use App\\SomeClass;",
      "use App\\AnotherClass;",
      "class TestClass {}",
    })
    local result = main.get_insertion_point()
    assert.are.equal(3, result)
  end)

  it("should handle mixed declare, namespace, and use statements", function()
    vim.api.nvim_buf_get_lines.returns({
      "<?php",
      "declare(strict_types=1);",
      "namespace App\\Test;",
      "use App\\SomeClass;",
      "class TestClass {}",
    })
    local result = main.get_insertion_point()
    assert.are.equal(4, result)
  end)

  it("should return correct insertion point for final class", function()
    vim.api.nvim_buf_get_lines.returns({
      "<?php",
      "namespace App\\Test;",
      "final class TestClass {}",
    })
    local result = main.get_insertion_point()
    assert.are.equal(2, result)
  end)

  it("should return correct insertion point for interface", function()
    vim.api.nvim_buf_get_lines.returns({
      "<?php",
      "namespace App\\Test;",
      "interface TestInterface {}",
    })
    local result = main.get_insertion_point()
    assert.are.equal(2, result)
  end)

  it("should return correct insertion point for trait", function()
    vim.api.nvim_buf_get_lines.returns({
      "<?php",
      "namespace App\\Test;",
      "trait TestTrait {}",
    })
    local result = main.get_insertion_point()
    assert.are.equal(2, result)
  end)

  it("should return correct insertion point for enum", function()
    vim.api.nvim_buf_get_lines.returns({
      "<?php",
      "namespace App\\Test;",
      "enum TestEnum {}",
    })
    local result = main.get_insertion_point()
    assert.are.equal(2, result)
  end)
end)
