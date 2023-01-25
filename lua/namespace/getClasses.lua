-- :GetAllClasses
-----------------

local tq       = require("vim.treesitter.query")
local List     = require("plenary.collections.py_list")
local pop      = require("namespace.ui")
local Job      = require("plenary.job")
local pclss    = require("namespace.classes")
local rt       = require("namespace.root")
local rootDir  = require("namespace.rootDir").searchRootDir()
local utils    = require("namespace.utils")
local csSearch = require("namespace.csSearch")
local rgSearch = require("namespace.rgSearch")

local M = {}

--getClassNames from the buffer
M.getClassNames = function()
    local root, bufnr = rt.getRoot("php")

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
(use_declaration (name) @use)
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

-- read composer.json
-- creates buffer
M.newBufnr = function(file)
    local ctbl = {}
    for line in io.lines(rootDir .. file) do
        table.insert(ctbl, line)
    end

    local buf = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_buf_set_lines(buf, 1, 1, true, ctbl)
    return buf
end

M.getComposerNamespace = function()
    -- get class namespace prefix
    local bufnr = M.newBufnr('composer.json')
    local root = rt.getRoot("json", bufnr)
    local query = vim.treesitter.parse_query(
        "json",
        [[
  (pair
      key: (string (string_content) @psr) (#eq? @psr "psr-4")
      value: (object (pair
          key: (string (string_content) @prefix)
          value: (string (string_content) @src_path (#match? @src_path "src|app|App/|Src/"))
      ))
  ) @a
  ]]
    )
    local composer = List({})
    for _, captures, _ in query:iter_matches(root, bufnr) do
        local prefix = tq.get_node_text(captures[2], bufnr)
        local source = tq.get_node_text(captures[3], bufnr)
        prefix = prefix:gsub("%\\", "")
        source = source:gsub("/", "")
        composer:insert(1, prefix)
        composer:insert(1, source)
    end
    vim.api.nvim_buf_delete(bufnr, { force = true })

    return composer
end

----------------------
--- check if class is native php class return user and php classes
----------------------
M.checkClasses = function(clss)
    local pcls = List({}) -- php classes
    local ucls = List({}) -- user classes

    for _, value in clss:iter() do
        if pclss:contains(value) then
            pcls:insert(1, "use " .. value .. ";")
        else
            ucls:insert(1, value)
        end
    end
    return pcls, ucls
end

----------------------
-- Delete existint imports from table-
----------------------
M.elimateClasses = function(all, usedclss)
    local c = List({})
    for _, value in all:iter() do
        if not usedclss:contains(value) then
            c:insert(1, value)
        end
    end
    return c
end

M.sort = function(cls)
    local data = { cls:unpack() }
    table.sort(data, function(a, b) return #a < #b end)
    return data
end

M.existingClasses = function()
    local root, bufnr = rt.getRoot("php")

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
    local bufnr = utils.getBuffer()
    local prefix = M.getComposerNamespace()[2]

    ---
    local fclss = M.getClassNames()
    local eclss = M.existingClasses()

    if #fclss == nil then return end
    if #eclss >= 1 then
        fclss = M.elimateClasses(fclss, eclss)
    end

    local phpclss, uclss = M.checkClasses(fclss)

    local ccclss = List({})
    ----
    for _, cls in uclss:iter() do
        local sr = csSearch.CSearch(cls)
        if #sr == 0 then
            sr = rgSearch.RSearch(List({ cls }), prefix)
            if sr == nil then
                vim.api.nvim_echo({ { "0 Lines Added", 'Function' }, { ' ' .. 0 } }, true, {})
            else
                ccclss:insert(1, sr:unpack())
            end
            if #sr > 1 then
                local buf_nr = utils.searchBufnr(sr)
                local ss = utils.searchParse(buf_nr)
                pop.popup(ss)
                sr = {}
            end
        end
        if #sr > 1 then
            local buf_nr = utils.searchBufnr(sr)
            local ss = utils.searchParse(buf_nr)
            pop.popup(ss)
        end
    end

    local class = List({}):concat(phpclss, ccclss)

    if #class >= 1 then
        local scls = M.sort(class) -- sort
        vim.api.nvim_buf_set_lines(bufnr, 1, 1, true, scls)
        vim.api.nvim_echo({ { "Lines Added", 'Function' }, { ' ' .. #scls } }, true, {})
    end
end

return M
