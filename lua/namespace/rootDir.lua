-- borrowd form lazyvim https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/util/init.lua

local M = {}
M.searchRootDir = function()
    local fd = Job:new({
        command = 'fd',
        args = { "-a", "composer.json", "-E", "node_modules", "-E", "vendor" },
    })
    fd:sync()
    return unpack(fd:result()):gsub("composer.json", "")
end

return M
