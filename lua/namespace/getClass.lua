local List = require("plenary.collections.py_list")
local pop = require("namespace.popui")
local search = require("namespace.search")
local utils = require("namespace.utils")
local tree = require("namespace.treesitter")
local native = require("namespace.classes")
local bf = require("namespace.buffer")

local M = {}

M.get = function(cWord, mbufnr)
    mbufnr = mbufnr or utils.get_bufnr()
    if vim.api.nvim_buf_get_option(mbufnr, "filetype") ~= "php" then return end
    local prefix = tree.namespace_prefix()
    cWord = cWord or vim.fn.escape(vim.fn.expand('<cword>'), [[\/]])
    local used = tree.namespaces_in_buffer() --  class

    local filtered_class = utils.class_filter(List({ cWord }), used) --
    if #filtered_class == 0 then return end

    if native:contains(cWord) then
        cWord = cWord:gsub("%\\\\", "\\")
        cWord = "use " .. cWord .. ";"
        if not used:contains(cWord) then
            M.add_to_buffer(cWord)
        end
    end

    local sr = search.CSearch(cWord)
    if #sr == 0 then
        sr = search.RSearch(List({ cWord }), prefix)
        if sr == nil then
            vim.api.nvim_echo({ { "0 Lines Added", 'Function' }, { ' ' .. 0 } }, true, {})
        elseif #sr == 1 then
            bf.add_to_buffer(sr:unpack(), mbufnr)
        elseif #sr > 1 then
            pop.popup(sr, mbufnr)
        end
    end

    local searched = tree.search_parse(sr) -- return namespace

    if #searched == 1 then
        local line = searched:unpack()
        line = line:gsub("%\\\\", "\\")
        line = "use " .. line .. ";"
        if not used:contains(line) then
            bf.add_to_buffer(line, mbufnr)
        end
    elseif #searched > 1 then
        pop.popup(searched, mbufnr)
    end

    -- vim.api.nvim_echo({ { "Lines Added", 'Function' }, { ' ' .. 1 } }, true, {})
    searched = List({})
end

return M
