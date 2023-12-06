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

    -- TODO remove as classes from the list     namespace_aliasing_clause
    -- if asclass and extends has the same name dont import it

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

    local searchResult = search.CSearch(cWord)
    if #searchResult == 0 then
        searchResult = search.RSearch(List({ cWord }), prefix)
        if #searchResult == 0 then
            vim.api.nvim_echo(
                { { "0 Lines Added", "Function" }, { " " .. 0 } },
                true,
                {}
            )
        elseif #searchResult == 1 then
            local line = searchResult:unpack()
            line = M.parseLine(line, mbufnr)
        elseif #searchResult > 1 then
            pop.popup({ { searchResult:unpack() } }, mbufnr) --requires double brackets to be able check size in popui
        end
        return
    end

    local searched = tree.search_parse(searchResult) -- return namespace

    if #searched == 1 then
        local line = searched:unpack()
        line = M.parseLine(line, mbufnr)
    elseif #searched > 1 then
        pop.popup({ { searched:unpack() } }, mbufnr) --requires double brackets to be able ch
    end

    -- vim.api.nvim_echo({ { "Lines Added", 'Function' }, { ' ' .. 1 } }, true, {})
    searched = {}
end

M.parseLine = function(line, mbufnr)
    line = line:gsub("%\\\\", "\\")
    line = "use " .. line .. ";"
    bf.add_to_buffer(line, mbufnr)
end

return M
