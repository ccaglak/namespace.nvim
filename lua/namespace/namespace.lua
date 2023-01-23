-- module represents a lua module for the plugin
local tq = require("vim.treesitter.query")
local List = require("plenary.collections.py_list")
local pop = require("namespace.ui")
local Job = require("plenary.job")
local pclss = require("namespace.classes")


local M = {}

function vim.fs.exists(name)
    local file, err = io.open(name, "r")
    if err ~= nil then return false end

    io.close(file)
    return true
end

-- getRoot
M.getRoot = function(language, bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    -- if vim.bo[bufnr].filetype ~= language then
    -- vim.notify "Invalid filetype *.php"
    -- return
    -- end
    local parser = vim.treesitter.get_parser(bufnr, language, {})
    local tree = parser:parse()[1]
    return tree:root(), bufnr
end

-- finds the root directory
M.rootDir = function()
    local root_dir
    for dir in vim.fs.parents(vim.api.nvim_buf_get_name(0)) do
        if vim.fn.isdirectory(dir .. "/.git") == 1 then
            root_dir = dir
            break
        elseif vim.fn.isdirectory(dir .. "/vendor") == 1 then
            root_dir = dir
            break
        end
    end
    return root_dir
end



--getClassNames from the buffer
M.getClassNames = function()
    local root, bufnr = M.getRoot("php")

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

--------------------------------------------
-- searchName
-----------------------------------
M.searchName = function(search)
    local rg = Job:new({
        command = 'rg',
        args = { "/" .. search .. ".php", "vendor/composer/autoload_classmap.php" },
    })
    rg:sync()
    return rg:result()
end

M.searchBufnr = function(search)
    local ctbl = List({ "<?php", "return array(" })
    local result = M.searchName(search)
    local all = List({}):concat(ctbl, result)
    all:push(");")


    local buf = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_buf_set_lines(buf, 0, 0, true, { unpack(all) })
    return buf
end



local function getBuffer(filename)
    local buf_exists = vim.fn.bufexists(filename) ~= 0
    if buf_exists then
        return vim.fn.bufnr(filename)
    end
    return 0
end

----------------------------
M.searchParse = function(class)
    local searched = List({})
    -- get class namespace prefix
    local bufnr = M.searchBufnr(class)
    local root = M.getRoot("php", bufnr)
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
-----------------------------------
--end
--------------------------------------------
local searchClss
-- searches the local directory for the class
-- TODO when main directory
M.fzfSearch = function(classes, prefix, dir)
    if #classes == 0 then
        return List({})
    end
    dir = dir or M.rootDir()
    local paths = List({})
    for _, class in classes:iter() do
        local fzf = Job:new({
            command = "fzf",
            writer = Job:new({
                command = "fd",
                args = { "-E", "vendor", "-E", "node_modules" },
                cwd = dir, --TODO--change it current directory later
            }),
            args = { "-e", "+i", "--filter", "/" .. class .. ".php" },
        })
        fzf:sync()
        local result = unpack(fzf:result()) -- hate the deprecated warning
        if result ~= nil then
            result = result:gsub("/", "\\")
            result = result:gsub(string.lower(prefix), "use " .. prefix)
            result = result:gsub("%.php", ";")
            paths:insert(1, result)
        end
        -- if result == nil then
        -- M.searchParse(class)           -- funds the missing import but cant get it to work
        -- paths:insert(1, ttbl)
        -- end
    end
    searchClss = paths

end


-- read composer.json
-- creates buffer
M.newBufnr = function(file)
    -- local rootDir = M.rootDir() --doesn't work yet
    if not vim.fs.exists(file) then
        vim.notify "root dir dont work"
        return
    end

    local ctbl = {}
    for line in io.lines(file) do
        table.insert(ctbl, line)
    end

    local buf = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_buf_set_lines(buf, 1, 1, true, ctbl)
    return buf
end

-- gets psr-4 prefix and autoload path
M.getComposerNamespace = function()
    -- get class namespace prefix
    local bufnr = M.newBufnr('composer.json')
    local root = M.getRoot("json", bufnr)
    local query = vim.treesitter.parse_query(
        "json",
        [[
  (pair
      key: (string (string_content) @psr) (#eq? @psr "psr-4")
      value: (object (pair
          key: (string (string_content) @prefix)
          value: (string (string_content) @src_path (#match? @src_path "src|src/|app|app/|App/|Src/"))
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
---  gets Existing use declarations
----------------------

M.getUsedClasses = function()
    local root, bufnr = M.getRoot("php")

    local query = vim.treesitter.parse_query("php", [[(namespace_use_declaration) @use]])
    local clsNames = List({})
    for n, captures, _ in query:iter_matches(root, bufnr) do
        local clsName = tq.get_node_text(captures[n], bufnr)
        if not clsNames:contains(clsName) then
            clsNames:insert(1, clsName)
        end
    end
    return clsNames
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

----------------------
--- Sort Imports - sort by import lengtn
----------------------

M.sort = function(cls)
    local data = { cls:unpack() }
    table.sort(data, function(a, b) return #a < #b end)
    return data
end

M.getAllClasses = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local prefix = M.getComposerNamespace()[2]
    local cls = M.getClassNames()
    local phpclss, userclss = M.checkClasses(cls)
    M.fzfSearch(userclss, prefix)

    local usedclss = M.getUsedClasses()
    local all = List({}):concat(phpclss, searchClss)
    local class = M.elimateClasses(all, usedclss)

    if #class >= 1 then
        local scls = M.sort(class) -- sort
        vim.api.nvim_buf_set_lines(bufnr, 3, 3, true, scls)
        vim.api.nvim_echo({ { "Lines Added", 'Function' }, { ' ' .. #scls } }, true, {})
    end
end

M.addToBuffer = function(line)
    local bufname = vim.api.nvim_buf_get_name(0)
    local buf = getBuffer(bufname)
    line = line:gsub("%\\\\", "\\")
    line = "use " .. line .. ";"
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 3, 3, true, { line })
end

M.getClass = function()
    local getCursorWord = vim.fn.escape(vim.fn.expand('<cword>'), [[\/]])
    local searched = M.searchParse(getCursorWord)
    local used = M.getUsedClasses()
    local fclass = M.elimateClasses(searched, used)
    if #searched == 1 then
        M.addToBuffer(fclass:unpack())
    elseif #searched > 1 then
        pop.popup(searched)
    else
        return
    end
    vim.api.nvim_echo({ { "Lines Added", 'Function' }, { ' ' .. #fclass } }, true, {})
    searched = List({})
end

return M
