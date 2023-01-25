local List = require("plenary.collections.py_list")
local tq = require("vim.treesitter.query")
local rt = require("namespace.root")
local pop = require("namespace.ui")
local csSearch = require("namespace.csSearch")
local rgSearch = require("namespace.rgSearch")
local utils = require("namespace.utils")
local native = require("namespace.classes")

local M = {}


M.addToBuffer = function(line)
    local bufname = vim.api.nvim_buf_get_name(0)
    local buf = utils.getBuffer(bufname)
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 3, 3, true, { line })
    vim.api.nvim_echo({ { "Lines Added", 'Function' }, { ' ' .. 1 } }, true, {})
end

M.get = function()
    local cWord = vim.fn.escape(vim.fn.expand('<cword>'), [[\/]])
    local used = utils.getUsedClasses()
    if native:contains(cWord) then
        cWord = cWord:gsub("%\\\\", "\\")
        cWord = "use " .. cWord .. ";"
        if not used:contains(cWord) then
            M.addToBuffer(cWord)
        end
        return
    end
    local sr = csSearch.CSearch(cWord)
    if #sr == 0 then
        sr = rgSearch.RSearch(List({ cWord }))
        M.addToBuffer(sr:unpack())
        if sr == nil then
            vim.api.nvim_echo({ { "0 Lines Added", 'Function' }, { ' ' .. 0 } }, true, {})
            return
        end
    end
    local bufnr = utils.searchBufnr(sr)
    local searched = utils.searchParse(bufnr)

    local fclass = utils.elimateClasses(searched, used)
    if #searched == 1 then
        local line = fclass:unpack()
        line = line:gsub("%\\\\", "\\")
        line = "use " .. line .. ";"
        if not used:contains(line) then
            M.addToBuffer(line)
            return
        end
    elseif #searched > 1 then
        pop.popup(searched)
        return
    end

    -- vim.api.nvim_echo({ { "Lines Added", 'Function' }, { ' ' .. 1 } }, true, {})
    searched = List({})
end

return M
