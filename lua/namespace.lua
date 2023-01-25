-- main module file
local ns = require("lua.namespace.getClasses")
local sort = require("namespace.sort")
local gc = require("namespace.getClass")

local M = {}
M.getAllClasses = function()
    ns.getAllClasses()
end

M.getClass = function()
    gc.getClass()
end

M.sortClass = function()
    sort.sort()
end

function M.reset()
    require("plenary.reload").reload_module("namespace")
end

return M
