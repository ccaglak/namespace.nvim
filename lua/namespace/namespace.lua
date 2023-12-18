-- Namespace generator

-- local util = require("namespace.utils")
local ts = require("namespace.treesitter")
local bf = require("namespace.buffer")
local utils = require("namespace.utils")

local M = {}

M.gen = function()
    local root = require("namespace.root").root()
    local path = vim.api.nvim_buf_get_name(0)

    local stat = vim.uv.fs_stat(path)
    if not stat or not stat.type or stat.type ~= "file" then
        path = vim.fn.fnamemodify(path, ":h")
    end

    path = path:gsub(root, "")

    local filename = vim.fn.fnamemodify(path, ":t")

    local bpath = path:gsub(filename, ""):sub(1, -2):gsub("/", "\\")

    local prefix = ts.namespace_prefix()
    if prefix == nil then
        return
    end

    local prefx = M.pascalCase(prefix[3], '\\\\')
    path = bpath:gsub(prefix[2], prefx)

    -- maybe it make better sense to upper case the first letter of the path
    if bpath == path then
        path = M.pascalCase(path)
    end

    path = "namespace " .. path .. ";"
    bf.add_to_buffer(path, nil, 3)
end

M.pascalCase = function(path, split)
    split = split or "\\"
    local split_path = utils.spliter(path, split)
    local custom_path = ""
    for _, value in pairs(split_path) do
        custom_path = custom_path .. (value:gsub("^%l", string.upper)) .. "\\"
    end
    return custom_path:sub(1, -2)
end

return M
