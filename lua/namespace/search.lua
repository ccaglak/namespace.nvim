local List = require("plenary.collections.py_list")
local Job = require("plenary.job")
local rt = require("namespace.root").root()

local sep = require('namespace.utils').path_sep()

local M = {}
M.CSearch = function(search)
    local rg = Job:new({
        command = 'rg',
        args = { sep .. search .. ".php", "vendor" .. sep .. "composer" .. sep .. "autoload_classmap.php" },
    })
    rg:sync()
    return rg:result()
end

M.get_file_namespace = function(path)
    function file_exists(file)
      local f = io.open(file, "rb")
      if f then f:close() end
      return f ~= nil
    end

    function lines_from(file)
      if not file_exists(file) then return {} end
      local lines = {}
      for line in io.lines(file) do
        lines[#lines + 1] = line
      end
      return lines
    end

    local lines = lines_from(path)
    for i, line in pairs(lines) do
        if line:find("^namespace") then
            return line:match("namespace (.*);")
        end
    end
end

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
            table.insert(namespaces, namespace)
        end
    end

    return namespaces
end

M._modify = function(result, prefix)
    result = result:gsub(rt, "")
    result = result:gsub("/", "\\")
    result = result:gsub(string.lower(prefix[1]), "use " .. prefix[2])
    result = result:gsub("%.php", ";")
end
return M
