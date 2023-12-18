local List = require("plenary.collections.py_list")
local pop = require("namespace.popui")
local search = require("namespace.search")
local utils = require("namespace.utils")
local tree = require("namespace.treesitter")
local native = require("namespace.classes")
local bf = require("namespace.buffer")

local M = {}

M.get = function(cWord, mbufnr, gcs)
    -- TODO if getClass called from getclasses skip few step
    gcs = gcs or false
    local prefix, used

    -- TODO remove as classes from the list namespace_aliasing_clause
    -- if asclass and extends has the same name dont import it
    -- *** remove local classes

    if not gcs == true then
        mbufnr = mbufnr or utils.get_bufnr()

        if vim.api.nvim_buf_get_option(mbufnr, "filetype") ~= "php" then
            return
        end

        prefix = tree.namespace_prefix()

        cWord = cWord or vim.fn.escape(vim.fn.expand("<cword>"), [[\/]])

        used = tree.namespaces_in_buffer() --  class

        local filtered_class = utils.class_filter(List({ cWord }), used)

        if #filtered_class == 0 then
            return
        end
    end

    if native:contains(cWord) then
        cWord = M.parseLine(cWord)
        bf.add_to_buffer(cWord, mbufnr)
        return
    end

    local localResult = search.LocalSearch(List({ cWord }), prefix)

    local composerResult = List({})

    if vim.fn.findfile("composer.json", ".;") then
        composerResult = search.CSearch(cWord)
    end

    local parsed_search_result = tree.search_parse(composerResult) -- return namespace

    parsed_search_result = M.class_parse(parsed_search_result)
    parsed_search_result = parsed_search_result:concat(localResult) -- concat two results
    parsed_search_result = M.unique(parsed_search_result)           -- unique
    if #parsed_search_result == 0 then return end

    if #parsed_search_result == 1 then
        local line = parsed_search_result:unpack()
        line = M.parseLine(line, mbufnr)
    elseif #parsed_search_result > 1 then
        pop.popup({ { parsed_search_result:unpack() } }, mbufnr) --requires double brackets to be able ch
    end

    -- vim.api.nvim_echo({ { "Lines Added", 'Function' }, { ' ' .. 1 } }, true, {})
    parsed_search_result = {}
end

M.parseLine = function(line, mbufnr)
    line = "use " .. line .. ";"
    bf.add_to_buffer(line, mbufnr)
end

M.class_parse = function(cls)
    local c = List({})
    for _, value in cls:iter() do
        value = value:gsub("%\\\\", "\\")
        c:insert(1, value)
    end
    return c
end

M.unique = function(list)
    local ret, hash = {}, {}
    for _, value in list:iter() do
        if not hash[value] then table.insert(ret, value) end
        hash[value] = true
    end

    return List(ret)
end

return M
