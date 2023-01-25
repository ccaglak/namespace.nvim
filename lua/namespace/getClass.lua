local List = require("plenary.collections.py_list")
local tq = require("vim.treesitter.query")
local rt = require("namespace.root")
local pop = require("namespace.ui")
local csSearch = require("namespace.csSearch")
local rgSearch = require("namespace.rgSearch")
local utils = require("namespace.utils")
local native = require("namespace.classes")

local M = {}



M.searchBufnr = function(searched)
    local ctbl = List({ "<?php", "return array(" })
    local all = List({}):concat(ctbl, searched)
    all:push(");")

    local buf = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_buf_set_lines(buf, 0, 0, true, { unpack(all) })
    return buf
end

M.searchParse = function(bufnr)
    local searched = List({})
    -- get class namespace prefix
    local root = rt.getRoot("php", bufnr)
    local query = vim.treesitter.parse_query(
        "php",
        [[
(array_element_initializer
  (string (string_value) @sv1)
   (binary_expression right: (string (string_value) @sv2 ))
  )
  ]]
    )
    for _, captures, _ in query:iter_matches(root, bufnr) do
        local ns = tq.get_node_text(captures[1], bufnr)
        local source = tq.get_node_text(captures[2], bufnr) -- gets the file path
        searched:insert(1, ns)
    end
    vim.api.nvim_buf_delete(bufnr, { force = true })
    return searched
end

M.addToBuffer = function(line)
    local bufname = vim.api.nvim_buf_get_name(0)
    local buf = utils.getBuffer(bufname)
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 1, 1, true, { line })
    vim.api.nvim_echo({ { "Lines Added", 'Function' }, { ' ' .. 1 } }, true, {})
end


M.getClass = function()
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
    if sr == nil then
        sr = rgSearch.RSearch(List({ cWord }))
        if sr == nil then
            vim.api.nvim_echo({ { "0 Lines Added", 'Function' }, { ' ' .. 0 } }, true, {})
            return
        end
    end
    local bufnr = M.searchBufnr(sr)
    local searched = M.searchParse(bufnr)

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
