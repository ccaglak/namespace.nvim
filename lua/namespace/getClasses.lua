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

    local allClasses = tree.get_class_names() -- gets the class names
    if #allClasses == 0 then
        return
    end

    local local_class = tree.get_file_class()           -- get the local_class name

    local existingClasses = tree.namespaces_in_buffer() --  namespace in buffer

    if #local_class ~= 0 then                           -- checks whether there is class in the file
        existingClasses:insert(1, local_class:unpack()) -- inserts local_class here to to get it filtered
    end


    if #existingClasses >= 1 then
        allClasses = utils.class_filter(allClasses, existingClasses)
    end
    if #allClasses == 0 then
        return
    end
    ----
    _G.nspace = gcls.localNamespace() -- get file namespace
    for _, cls in ipairs(allClasses) do
        gcls.get(cls, mbufnr, true)   -- calling get_class
    end
    _G.nspace = nil                   -- reset it here to prevent
end

return M
