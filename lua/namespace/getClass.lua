local List = require("plenary.collections.py_list")
local pop = require("namespace.popui")
local search = require("namespace.search")
local utils = require("namespace.utils")
local tree = require("namespace.treesitter")
local native = require("namespace.classes")
local bf = require("namespace.buffer")

local M = {}

M.get = function(cWord, mbufnr, gcs)
    if  vim.api.nvim_get_option_value("filetype", { buf = 0 }) ~= "php" then
        return
    end
    gcs = gcs or false

    local used, prefix

    if vim.fn.findfile("composer.json", ".;") then
        prefix = tree.namespace_prefix()
        if prefix == nil then
            print("Please check composer.json")
        end
    end

    if not gcs == true then
        cWord = cWord or vim.fn.escape(vim.fn.expand("<cword>"), [[\/]])
        if cWord == nil then
            return
        end

        mbufnr = mbufnr or utils.get_bufnr()

        used = tree.namespaces_in_buffer() --  class

        local filtered_class = utils.class_filter(List({ cWord }), used)

        if #filtered_class == 0 then
            return
        end
        _G.nspace = M.localNamespace() -- get file namespace
    end

    if native:contains(cWord) then
        cWord = M.parseLine(cWord, mbufnr)
        return
    end

    local localResult = search.LocalSearch(List({ cWord }), prefix)

    local composerResult
    if vim.fn.findfile("composer.json", ".;") then
        composerResult = search.CSearch(cWord)
    end

    local parsed_search_result
    if composerResult ~= nil then
        parsed_search_result = tree.composer_search_parse(composerResult) -- return namespace
        parsed_search_result = M.class_line_parse(parsed_search_result)
    end

    if localResult ~= nil then
        parsed_search_result = parsed_search_result:concat(localResult) -- concat two results
    end

    if parsed_search_result == nil then
        return
    end

    parsed_search_result = M.unique(parsed_search_result) -- unique

    --     _G.ns = M.localNamespace() -- intialized in line 40 and getclasses before after for loop
    --     this needs to be fixed
    if #parsed_search_result == 1 and _G.nspace ~= nil then
        -- local pre = prefix[3]:sub(1, -3):gsub("%\\\\", "\\")
        -- local same = _G.ns == pre
        -- if same then
        local parse = parsed_search_result:unpack()
        local sp = utils.spliter(parse, "\\")
        local ns = utils.spliter(_G.nspace, "\\")
        if #sp - 1 == #ns then
            return
        end
    end

    -----------

    if #parsed_search_result == 1 then
        local line = parsed_search_result:unpack()
        M.parseLine(line, mbufnr)
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

M.localNamespace = function()
    for line in io.lines(vim.api.nvim_buf_get_name(0)) do
        if line:find("^namespace") then
            return line:match("namespace (.*);")
        end
    end
end

M.class_line_parse = function(cls)
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
        if not hash[value] then
            table.insert(ret, value)
        end
        hash[value] = true
    end

    return List(ret)
end

return M
