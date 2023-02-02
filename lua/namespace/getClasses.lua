local tq     = require("vim.treesitter.query")
local List   = require("plenary.collections.py_list")
local pop    = require("namespace.popui")
local tree   = require("namespace.treesitter")
local rt     = require("namespace.root").root() -- root directory maybe it should be more clear
local utils  = require("namespace.utils")
local search = require("namespace.search")


local M = {}

--get_class_names from the buffer
M.get_class_names = function()
    local root, bufnr = tree.get_root("php")

    local query = vim.treesitter.parse_query(
        "php",
        [[
(scoped_call_expression scope:(name) @sce)
(named_type (name) @named)
(base_clause (name) @extends )
(class_interface_clause (name) @implements)
(class_constant_access_expression (name) @static (name))
(simple_parameter type: (union_type (named_type (name) @name)))
(object_creation_expression (name) @objcreation)
(use_declaration (name) @use )
((binary_expression
left: (class_constant_access_expression)
right: (name) @cls
) @b (#match? @b "instanceof"))
  ]]
    )

    local clsNames = List({})
    for n, captures, _ in query:iter_matches(root, bufnr) do
        local clsName = tq.get_node_text(captures[n], bufnr)
        if not clsNames:contains(clsName) then
            clsNames:insert(1, clsName)
        end
    end
    return clsNames
end

M.get_file_class = function()
    local root, bufnr = tree.get_root("php")

    local query = vim.treesitter.parse_query("php", [[(class_declaration name:(name) @name)]])
    local clsNames = List({})
    for n, captures, _ in query:iter_matches(root, bufnr) do
        local clsName = tq.get_node_text(captures[n], bufnr)
        if not clsNames:contains(clsName) then
            clsNames:insert(1, clsName)
        end
    end
    return clsNames
end

M.namespaces_in_buffer = function()
    local root, bufnr = tree.get_root("php")

    local query = vim.treesitter.parse_query("php", [[
        (namespace_use_clause (qualified_name (name) @name))
        (namespace_use_clause (name) @pname)
        ]])
    local clsNames = List({})
    for n, captures, _ in query:iter_matches(root, bufnr) do
        local clsName = tq.get_node_text(captures[n], bufnr)
        if not clsNames:contains(clsName) then
            clsNames:insert(1, clsName)
        end
    end
    return clsNames
end

M.get = function()
    if vim.bo.filetype ~= "php" then return end
    local bufnr = utils.get_bufnr()
    local prefix = tree.namespace_prefix()
    ---
    local fclss = M.get_class_names() -- gets the class names
    local local_class = M.get_file_class() -- get the local_class name
    local eclss = M.namespaces_in_buffer() --  class
    if #local_class ~= 0 then -- checks whether there is class in the file
        eclss:insert(1, local_class:unpack()) -- insert here to to get it filtered
    end

    if #fclss == 0 then return end -- whole block could be a function simplify
    if #eclss >= 1 then
        fclss = utils.class_filter(fclss, eclss)
    end
    if #fclss == 0 then return end

    local phpclss, uclss = utils.class_check(fclss)
    local ccclss = List({})
    ----
    for _, cls in uclss:iter() do
        local sr = search.CSearch(cls)
        if #sr == 0 then
            sr = search.RSearch(List({ cls }), prefix)
            if sr == nil then
                vim.api.nvim_echo({ { "0 Lines Added", 'Function' }, { ' ' .. 0 } }, true, {})
                return
            elseif #sr == 1 then
                local line = sr:unpack()
                line = line:gsub("%\\\\", "\\")
                line = "use " .. line .. ";"
                ccclss:insert(1, line)
            elseif #sr > 1 then
                pop.popup(sr, bufnr)
            end
            goto continue
        end
        if #sr > 1 then
            local buf_nr = tree.create_search_bufnr(sr)
            local ss = tree.search_parse(buf_nr)
            pop.popup(ss, bufnr)

        elseif #sr == 1 then
            local buf_nr = tree.create_search_bufnr(sr)
            local ss = tree.search_parse(buf_nr)
            local line = ss:unpack()
            line = line:gsub("%\\\\", "\\")
            line = "use " .. line .. ";"
            ccclss:insert(1, line)
        end
        ::continue::
    end

    local class = List({}):concat(phpclss, ccclss)

    if #class >= 1 then
        local scls = { class:unpack() }
        table.sort(scls, function(a, b) return #a < #b end)
        local insertion_point = utils.get_insertion_point(bufnr)
        vim.api.nvim_buf_set_lines(bufnr, insertion_point, insertion_point, true, scls)
    end
end

return M
