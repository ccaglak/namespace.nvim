local tq     = require("vim.treesitter.query")
local List   = require("plenary.collections.py_list")
local pop    = require("namespace.popui")
local tree   = require("namespace.treesitter")
local utils  = require("namespace.utils")
local search = require("namespace.search")
local gcls   = require("namespace.getClass")

local co = coroutine
local M  = {}

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

-- gets the main class
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
    if vim.api.nvim_buf_get_option(0, "filetype") ~= "php" then return end
    local mbufnr = utils.get_bufnr()

    local fclss = M.get_class_names() -- gets the class names
    local local_class = M.get_file_class() -- get the local_class name
    local eclss = M.namespaces_in_buffer() --  namespace in buffer
    if #local_class ~= 0 then -- checks whether there is class in the file
        eclss:insert(1, local_class:unpack()) -- inserts local_class here to to get it filtered
    end

    if #fclss == 0 then return end -- whole block could be a function simplify
    if #eclss >= 1 then
        fclss = utils.class_filter(fclss, eclss)
    end
    if #fclss == 0 then return end
    ----
    local ptbl = {}
    for _, cls in fclss:iter() do
        local p = gcls.get(cls, mbufnr) -- get_class
        if p ~= nil then
            table.insert(ptbl, p)
        end
    end
    pop.popup(ptbl, mbufnr)

end

return M
