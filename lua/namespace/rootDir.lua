-- borrowd form lazyvim https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/util/init.lua

local M = {}
M.root_patterns = { ".git", "lua", "vendor", "node_modules" }
function M.searchRootDir()
    return vim.fn.expand("%:p:h") .. "/"
end

return M
