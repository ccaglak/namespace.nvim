-- sort
local tq = require("vim.treesitter.query")
local List = require("plenary.collections.py_list")
local rt = require("namespace.root")

local M = {}

local bufnr = 0
local root = 0
M.namespaces = function()
    local n = {}
    root, bufnr = rt.getRoot('php')

    if vim.bo[bufnr].filetype ~= "php" then
        require("namespace").reset()
    end



    local query = vim.treesitter.parse_query("php", [[(namespace_use_declaration) @use]])
    local clsNames = List({})
    for _, captures, me in query:iter_matches(root, bufnr) do
        local clsName = tq.get_node_text(captures[1], bufnr)
        if not clsNames:contains(clsName) then
            clsNames:insert(1, clsName)
        end
        for _, key in ipairs(captures) do
            local row, _, _, _ = vim.treesitter.get_node_range(key)
            table.insert(n, row)
        end

    end

    return clsNames, { n[1], n[#n] }
end

M.sort = function()
    local namespaces, ln = M.namespaces()
    vim.api.nvim_buf_set_lines(bufnr, ln[1], ln[2] + 1, true, {})
    table.sort(namespaces, function(a, b) return #a < #b end)
    vim.api.nvim_buf_set_lines(bufnr, ln[1], ln[1], true, { namespaces:unpack() })
end


return M
