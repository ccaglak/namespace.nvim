-- main module file

if not vim.uv then
    vim.uv = vim.loop
end

local M = {}
M.get_classes = function()
    require("namespace.getClasses").get()
end

M.get_class = function()
    require("namespace.getClass").get()
end

M.class_as = function()
    require("namespace.classAs").open()
end

M.name_space = function()
    require("namespace.namespace").gen()
end


return M
