local List = require("plenary.collections.py_list")
local pop = require("namespace.popui")
local search = require("namespace.search")
local utils = require("namespace.utils")
local tree = require("namespace.treesitter")
local native = require("namespace.classes")

local M = {}

M.add_to_buffer = function(line, bufnr)
    bufnr = bufnr or utils.get_bufnr()
    local insertion_point = utils.get_insertion_point()
    vim.api.nvim_buf_set_lines(bufnr, insertion_point, insertion_point, true, { line })
    vim.api.nvim_echo({ { "Lines Added", 'Function' }, { ' ' .. 1 } }, true, {})
end

M.get = function()
    if vim.bo.filetype ~= "php" then return end
    local prefix = tree.namespace_prefix()
    local mbufnr = utils.get_bufnr()
    local cWord = vim.fn.escape(vim.fn.expand('<cword>'), [[\/]])
    local used = tree.get_all_namespaces()

    if native:contains(cWord) then
        cWord = cWord:gsub("%\\\\", "\\")
        cWord = "use " .. cWord .. ";"
        if not used:contains(cWord) then
            M.add_to_buffer(cWord)
        end
        return
    end
    local sr = search.CSearch(cWord)
    if #sr == 0 then
        sr = search.RSearch(List({ cWord }), prefix)
        if sr == nil then
            vim.api.nvim_echo({ { "0 Lines Added", 'Function' }, { ' ' .. 0 } }, true, {})
        elseif #sr == 1 then
            M.add_to_buffer(sr:unpack(), mbufnr)
        elseif #sr > 1 then
            pop.popup(sr, mbufnr)
        end
    end
    local bufnr = tree.create_search_bufnr(sr)
    local searched = tree.search_parse(bufnr)

    local fclass = utils.class_filter(searched, used)
    if #searched == 1 then
        local line = fclass:unpack()
        line = line:gsub("%\\\\", "\\")
        line = "use " .. line .. ";"
        if not used:contains(line) then
            M.add_to_buffer(line, mbufnr)
            return
        end
    elseif #searched > 1 then
        pop.popup(searched, mbufnr)
        return
    end

    -- vim.api.nvim_echo({ { "Lines Added", 'Function' }, { ' ' .. 1 } }, true, {})
    searched = List({})
end

return M
