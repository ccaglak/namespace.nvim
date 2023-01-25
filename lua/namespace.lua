-- main module file
local ns = require("namespace.namespace")
local sort = require("namespace.sort")
local gc = require("namespace.getClass")

local M = {}
M.config = {
    -- default config
    -- opt = "Hello!",
}

-- setup is the public method to setup your plugin
M.setup = function(args)
    -- you can define your setup function here. Usually configurations can be merged, accepting outside params and
    -- you can also put some validation here for those.
    M.config = vim.tbl_deep_extend("force", M.config, args or {})
end

-- "hello" is a public method for the plugin
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
