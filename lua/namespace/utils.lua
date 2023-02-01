local List   = require("plenary.collections.py_list")
local native = require("namespace.classes")

local M = {}

M.path_sep = function()
    local win = vim.loop.os_uname().sysname == 'Darwin' or "Linux"
    return win and '/' or '\\'
end

M.absolute = function()
    return vim.loop.cwd()
end


M.get_bufnr = function(filename)
    filename = filename or vim.api.nvim_buf_get_name(0)
    local buf_exists = vim.fn.bufexists(filename) ~= 0
    if buf_exists then
        return vim.fn.bufnr(filename)
    end
    return 0
end

----------------------
--- check if class is native php class return user and php classes
----------------------
M.class_check = function(clss)
    local php_cls = List({}) -- php classes
    local user_cls = List({}) -- user classes

    for _, value in clss:iter() do
        if native:contains(value) then
            php_cls:insert(1, "use " .. value .. ";")
        else
            user_cls:insert(1, value)
        end
    end
    return php_cls, user_cls
end

----------------------
-- Delete existint imports from table-
----------------------
M.class_filter = function(all, usedclss)
    local c = List({})
    for _, value in all:iter() do
        if not usedclss:contains(value) then
            c:insert(1, value)
        end
    end
    return c
end



return M
