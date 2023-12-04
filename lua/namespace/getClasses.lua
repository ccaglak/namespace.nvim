local pop = require("namespace.popui")
local tree = require("namespace.treesitter")
local utils = require("namespace.utils")
local gcls = require("namespace.getClass")

local M = {}


M.get = function()
    if vim.api.nvim_buf_get_option(0, "filetype") ~= "php" then
        return
    end
    local mbufnr = utils.get_bufnr()

    local fclss = tree.get_class_names()      -- gets the class names
    local local_class = tree.get_file_class() -- get the local_class name

    local eclss = tree.namespaces_in_buffer() --  namespace in buffer

    if #local_class ~= 0 then                 -- checks whether there is class in the file
        eclss:insert(1, local_class:unpack()) -- inserts local_class here to to get it filtered
    end

    if #fclss == 0 then
        return
    end -- whole block could be a function simplify

    if #eclss >= 1 then
        fclss = utils.class_filter(fclss, eclss)
    end
    if #fclss == 0 then
        return
    end
    ----
    local ptbl = {}
    for _, cls in ipairs(fclss) do
        local p = gcls.get(cls, mbufnr) -- get_class
        if p ~= nil then
            table.insert(ptbl, p)
        end
    end

    pop.popup(ptbl, mbufnr)
end

return M
