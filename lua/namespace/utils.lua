local List   = require("plenary.collections.py_list")
local native = require("namespace.classes")

local M      = {}

M.path_sep   = function()
    local win = vim.loop.os_uname().sysname == 'Darwin' or "Linux"
    return win and '/' or '\\'
end

M.absolute   = function()
    return vim.loop.cwd()
end

function table.unique(list)
    local ret, hash = {}, {}
    for _, value in ipairs(list) do
        if not hash[value] then table.insert(ret, value) end
        hash[value] = true
    end

    return ret
end

----------------------
--- splits string by separater sep
----------------------
M.spliter = function(path, sep)
    sep = sep or "."
    local format = string.format("([^%s]+)", sep)
    local t = {}
    for str in string.gmatch(path, format) do
        table.insert(t, str)
    end
    return t
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
    local php_cls = List({})  -- php classes
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

----------------------
-- Get the line number to insert new use statements
-- based on the current structure of the file
----------------------
M.get_insertion_point = function(bufnr)
    bufnr = bufnr or M.get_bufnr()
    local content = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    -- default to line 3
    local insertion_point = 3
    local namespace_line_number = nil
    local last_use_statement_line_number = nil


    for i, line in ipairs(content) do
        if line:find("^(namespace|use)") then
            if line:find("^namespace") then
                namespace_line_number = i
            end

            if line:find("^use") then
                last_use_statement_line_number = i
            end
        end
    end

    if namespace_line_number then
        if not last_use_statement_line_number then
            -- insert an empty line after the namespace
            vim.api.nvim_buf_set_lines(bufnr, namespace_line_number, namespace_line_number, true, { "" })
        end
        insertion_point = namespace_line_number + 1
    end

    if last_use_statement_line_number then
        insertion_point = last_use_statement_line_number
    end


    return insertion_point
end

return M
