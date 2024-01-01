-- main module file

local gcs = require("namespace.getClasses")
local gc = require("namespace.getClass")
local as = require("namespace.classAs")
local ns = require("namespace.namespace")

local M = {}
M.get_classes = function()
    gcs.get()
end

M.get_class = function()
    gc.get()
end

M.sort_classes = function()
    print("Deprecated: formatters does this feature")
end

M.class_as = function()
    as.open()
end

M.name_space = function()
    ns.gen()
end


return M
