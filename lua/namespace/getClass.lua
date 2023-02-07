local List = require("plenary.collections.py_list")
local pop = require("namespace.popui")
local search = require("namespace.search")
local utils = require("namespace.utils")
local tree = require("namespace.treesitter")
local native = require("namespace.classes")
local bf = require("namespace.buffer")

local M = {}

M.get = function(cWord, mbufnr)
    local gcls = false
    if cWord == nil then gcls = true end
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
            bf.add_to_buffer(cWord, mbufnr)
        end
    end

    local sr = search.CSearch(cWord)
    if #sr == 0 then
        sr = search.RSearch(List({ cWord }), prefix)
        if sr == nil then
            vim.api.nvim_echo({ { "0 Lines Added", 'Function' }, { ' ' .. 0 } }, true, {})
        elseif #sr == 1 then
            local line = sr:unpack()
            line = line:gsub("%\\\\", "\\")
            line = "use " .. line .. ";"
            bf.add_to_buffer(line, mbufnr)
        elseif #sr > 1 then
            -- pop.popup(sr, mbufnr)
            if gcls == false then
                return { sr:unpack() }
            end
            pop.popup({ { sr:unpack() } }, mbufnr) --requires double brackets to be able check size in popui
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
        if gcls == false then
            return { searched:unpack() }
        end
        pop.popup({ { searched:unpack() } }, mbufnr) --requires double brackets to be able check size in popui
        -- pop.popup(searched, mbufnr)
    end

    -- vim.api.nvim_echo({ { "Lines Added", 'Function' }, { ' ' .. 1 } }, true, {})
    searched = List({})
end

return M
