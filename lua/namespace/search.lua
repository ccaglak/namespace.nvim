local List = require("plenary.collections.py_list")
local Job  = require("plenary.job")
local rt   = require("namespace.root").root()
local sep  = require('namespace.utils').path_sep()
local util = require('namespace.utils')



local M = {}

-- search in composer autoload_classmap
M.CSearch = function(search)
    if util.checkFileReadable('composer.json') == nil then
        return {}
    end
    local rg = Job:new({
        command = 'rg',
        args = { sep .. search .. ".php", "vendor" .. sep .. "composer" .. sep .. "autoload_classmap.php" },
    })
    rg:sync()
    return rg:result()
end

-- loads the file to get the namespace,
M.get_file_namespace = function(file)
    local function file_exists(fl)
        local f = io.open(fl, "rb")
        if f then f:close() end
        return f ~= nil
    end

    if not file_exists(file) then return {} end
    for line in io.lines(file) do
        if line:find("^namespace") then
            return line:match("namespace (.*);")
        end
    end
end

-- search in root directory
M.RSearch = function(classes, prefix)
    prefix = prefix or { "app", "App" }

    if #classes == 0 then
        return List({})
    end
    -- dir = dir or M.rootDir()
    local namespaces = List({})
    for _, class in classes:iter() do
        local rg = Job:new({
            command = "rg",
            -- rg -g 'Route.php' --files ./
            args = { "-g", class .. '.php', "--files", rt, "-g", "!node_modules/" },
        })
        rg:sync()
        local result = unpack(rg:result())
        if result ~= nil then
            local namespace = M.get_file_namespace(result) .. "\\" .. class
            namespaces:insert(1, namespace)
        end
    end

    return namespaces
end


return M
