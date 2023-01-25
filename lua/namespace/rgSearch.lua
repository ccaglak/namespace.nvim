local List = require("plenary.collections.py_list")
local Job = require("plenary.job")
local rootDir = require("namespace.rootDir").searchRootDir()

local M = {}
M.RSearch = function(classes, prefix)
    prefix = prefix or "app"
    if #classes == 0 then
        return List({})
    end
    -- dir = dir or M.rootDir()
    local paths = List({})
    for _, class in classes:iter() do
        local rg = Job:new({
            command = "rg",
            -- rg -g 'Route.php' --files ./
            args = { "-g", class .. '.php', "--files", rootDir, "-g", "!node_modules/" },
        })
        rg:sync()
        local result = unpack(rg:result())
        if result ~= nil then
            result = result:gsub(rootDir, "")
            result = result:gsub("/", "\\")
            result = result:gsub(string.lower(prefix), "use " .. prefix)
            result = result:gsub("%.php", ";")
            paths:insert(1, result)
        end
    end
    return paths

end

return M
