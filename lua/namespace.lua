-- main module file

local ns = require("namespace.getClasses")
local gc = require("namespace.getClass")
local as = require('namespace.asClass')

local M = {}
M.get_classes = function()
    ns.get()
end

M.get_class = function()
    gc.get()
end

M.sort_classes = function()
    -- sort.sort()
    print('Deprecated: formatters does this feature')
end

M.as_class = function()
    as.open()
end

return M
