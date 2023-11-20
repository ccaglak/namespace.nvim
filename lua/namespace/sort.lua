-- sort
local tq = require("vim.treesitter")
local List = require("plenary.collections.py_list")
local tree = require("namespace.treesitter")

local M = {}

local bufnr = 0
local root = 0
M.namespaces = function()
    root, bufnr = tree.get_root('php')

    local query = vim.treesitter.query.parse("php", [[(namespace_use_declaration) @use]])
    local namespaces = List({})
    local line = {}
    for _, captures, _ in query:iter_matches(root, bufnr) do
        local clsName = tq.get_node_text(captures[1], bufnr)
        if not namespaces:contains(clsName) then
            namespaces:insert(1, clsName)
        end
        for _, key in ipairs(captures) do
            local row, _, _, _ = vim.treesitter.get_node_range(key)
            table.insert(line, row)
        end

    end

    return namespaces, { line[1], line[#line] }
end

M.sort = function()
    if vim.bo.filetype ~= "php" then return end
    local namespaces, line = M.namespaces()
    vim.api.nvim_buf_set_lines(bufnr, line[1], line[2] + 1, true, {})
    table.sort(namespaces, function(a, b) return #a < #b end)
    vim.api.nvim_buf_set_lines(bufnr, line[1] + 1, line[1] + 1, true, { namespaces:unpack() })
end


return M
