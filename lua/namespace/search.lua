local List = require("plenary.collections.py_list")
local Job = require("plenary.job")
local rt = require("namespace.root").root()

local M = {}
M.CSearch = function(search)
    local rg = Job:new({
        command = 'rg',
        args = { "/" .. search .. ".php", "vendor/composer/autoload_classmap.php" },
    })
    rg:sync()
    return rg:result()
end

M.RSearch = function(classes, prefix)
    prefix = prefix or { "app", "App" }

    if #classes == 0 then
        return List({})
    end
    -- dir = dir or M.rootDir()
    local paths = List({})
    for _, class in classes:iter() do
        local rg = Job:new({
            command = "rg",
            -- rg -g 'Route.php' --files ./
            args = { "-g", class .. '.php', "--files", rt, "-g", "!node_modules/" },
        })
        rg:sync()
        local result = unpack(rg:result())
        if result ~= nil then
            paths:insert(1, result)
        end
    end
    return paths

end

M._modify = function(result, prefix)
    result = result:gsub(rt, "")
    result = result:gsub("/", "\\")
    result = result:gsub(string.lower(prefix[1]), "use " .. prefix[2])
    result = result:gsub("%.php", ";")
end
return M
