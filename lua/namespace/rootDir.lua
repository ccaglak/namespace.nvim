-- borrowd form lazyvim https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/util/init.lua

local M = {}
M.searchRootDir = function()
    return vim.fn.expand("%:p:h") .. "/"
end

return M
