-- Namespace generator

-- local util = require("namespace.utils")
local rt = require("namespace.root")
local ts = require("namespace.treesitter")
local bf = require("namespace.buffer")

local M = {}

M.gen = function()
    local root = rt.root()
    local path = vim.api.nvim_buf_get_name(0)
    local stat = vim.uv.fs_stat(path)
    if not stat or not stat.type or stat.type ~= "file" then
        path = vim.fn.fnamemodify(path, ":h")
    end

    path = path:gsub(root, "")

    local filename = vim.fn.fnamemodify(path, ":t")

    path = path:gsub(filename, ""):sub(1, -2):gsub("/", "\\")

    local prefix = ts.namespace_prefix()

    path = path:gsub(prefix[1], prefix[2])

    if path == "" then
        return
    end

    path = "namespace " .. path .. ";"
    bf.add_to_buffer(path, nil, 2)
end

return M
