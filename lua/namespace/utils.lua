local tq = require("vim.treesitter.query")
local List = require("plenary.collections.py_list")
local pclss = require("namespace.classes")
local rt = require("namespace.root")

local M = {}


M.getBuffer = function(filename)
    filename = filename or vim.api.nvim_buf_get_name(0)
    local buf_exists = vim.fn.bufexists(filename) ~= 0
    if buf_exists then
        return vim.fn.bufnr(filename)
    end
    return 0
end

M.getUsedClasses = function()
    local root, bufnr = rt.getRoot("php")

    local query = vim.treesitter.parse_query("php", [[(namespace_use_declaration) @use]])
    local clsNames = List({})
    for n, captures, _ in query:iter_matches(root, bufnr) do
        local clsName = tq.get_node_text(captures[n], bufnr)
        if not clsNames:contains(clsName) then
            clsNames:insert(1, clsName)
        end
    end
    return clsNames
end



----------------------
--- check if class is native php class return user and php classes
----------------------
M.checkClasses = function(clss)
    local pcls = List({}) -- php classes
    local ucls = List({}) -- user classes

    for _, value in clss:iter() do
        if pclss:contains(value) then
            pcls:insert(1, "use " .. value .. ";")
        else
            ucls:insert(1, value)
        end
    end
    return pcls, ucls
end

----------------------
-- Delete existint imports from table-
----------------------
M.elimateClasses = function(all, usedclss)
    local c = List({})
    for _, value in all:iter() do
        if not usedclss:contains(value) then
            c:insert(1, value)
        end
    end
    return c
end

return M
