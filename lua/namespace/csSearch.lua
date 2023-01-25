local Job = require("plenary.job")

local M = {}
M.CSearch = function(search)
    local rg = Job:new({
        command = 'rg',
        args = { "/" .. search .. ".php", "vendor/composer/autoload_classmap.php" },
    })
    rg:sync()
    return rg:result()
end


return M
