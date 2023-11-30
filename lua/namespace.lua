-- main module file
local ns = require("namespace.getClasses")
local sort = require("namespace.sort")
local gc = require("namespace.getClass")

local M = {}
M.get_classes = function()
    ns.get()
end

M.get_class = function()
    gc.get()
end

M.sort_classes = function()
    -- sort.sort()
    print('Deprecated')
end

return M
