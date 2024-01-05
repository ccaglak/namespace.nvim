local ts             = require("vim.treesitter")
local List           = require("plenary.collections.py_list")

local M              = {}

M.get_root           = function(language, bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local parser = ts.get_parser(bufnr, language, {})
    local tree = parser:parse()[1]
    return tree:root(), bufnr
end

-- gets the class in the buffer
M.get_file_class     = function()
    local root, bufnr = M.get_root("php")

    local query =
        ts.query.parse("php", [[(class_declaration name:(name) @name)]])
    local clsNames = List({})
    for n, captures, _ in query:iter_matches(root, bufnr) do
        local clsName = ts.get_node_text(captures[n], bufnr)
        if not clsNames:contains(clsName) then
            clsNames:insert(1, clsName)
        end
    end
    return clsNames
end

-- check if extendend class in folder if so ignore
M.get_extended_class = function()
    local root, bufnr = M.get_root("php")

    local query = ts.query.parse("php", [[(base_clause (name) @extends )]])
    local clsNames = List({})
    for n, captures, _ in query:iter_matches(root, bufnr) do
        local clsName = ts.get_node_text(captures[n], bufnr)
        if not clsNames:contains(clsName) then
            clsNames:insert(1, clsName)
        end
    end
    return clsNames
end

M.get_class_names    = function()
    local root, bufnr = M.get_root("php")

    local query = ts.query.parse(
        "php",
        [[
        (attribute (name) @att)
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
        local clsName = ts.get_node_text(captures[n], bufnr)
        if not clsNames:contains(clsName) then
            clsNames:insert(1, clsName)
        end
    end
    return clsNames
end

-- (namespace_aliasing_clause)

M.get_all_namespaces = function()
    local root, bufnr = M.get_root("php")

    local query = ts.query.parse("php", [[(namespace_use_declaration) @use]])
    local clsNames = List({})
    for n, captures, _ in query:iter_matches(root, bufnr) do
        local clsName = ts.get_node_text(captures[n], bufnr)
        if not clsNames:contains(clsName) then
            clsNames:insert(1, clsName)
        end
    end
    return clsNames
end

M.get_all_aliases    = function()
    local root, bufnr = M.get_root("php")

    local query = ts.query.parse("php", [[(namespace_aliasing_clause (name) @alias)]])
    local clsNames = List({})
    for n, captures, _ in query:iter_matches(root, bufnr) do
        local clsName = ts.get_node_text(captures[n], bufnr)
        if not clsNames:contains(clsName) then
            clsNames:insert(1, clsName)
        end
    end
    return clsNames
end



M.namespaces_in_buffer = function()
    local root, bufnr = M.get_root("php")

    local query = ts.query.parse("php", [[
        (namespace_use_clause (qualified_name (name) @name))
        (namespace_use_clause (name) @pname)
        ]])
    local clsNames = List({})
    for n, captures, _ in query:iter_matches(root, bufnr) do
        local clsName = ts.get_node_text(captures[n], bufnr)
        if not clsNames:contains(clsName) then
            clsNames:insert(1, clsName)
        end
    end
    return clsNames
end

M.composer_search_parse = function(sr)
    local searched = List({})
    local bufnr = M.create_search_bufnr(sr)
    local root = M.get_root("php", bufnr)
    local query = ts.query.parse(
        "php",
        [[
(array_element_initializer
  (string (string_value) @sv1)
   (binary_expression right: (string (string_value) @sv2 ))
  )
  ]]
    )
    for _, captures, _ in query:iter_matches(root, bufnr) do
        local ns = ts.get_node_text(captures[1], bufnr)
        local source = ts.get_node_text(captures[2], bufnr) -- gets the file path for future projects
        searched:insert(1, ns)
    end
    vim.api.nvim_buf_delete(bufnr, { force = true })
    return searched
end

M.create_search_bufnr = function(searched)
    local ctbl = List({ "<?php", "return array(" })
    local all = List({}):concat(ctbl, searched)
    all:push(");")

    local buf = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_buf_set_lines(buf, 0, 0, true, { unpack(all) })
    return buf
end


-- read composer.json
-- creates buffer
M.new_composer_buffer = function(file)
    local pathFile = require('namespace.utils').checkFileReadable(file)
    if pathFile == nil then
        return
    end

    local ctbl = vim.fn.readfile(pathFile)
    if #ctbl == 0 then
        return
    end

    local buf = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_buf_set_lines(buf, 1, 1, true, ctbl)
    return buf
end

-- gets the prefix from composer but it should be secondary option
M.namespace_prefix = function()
    local bufnr = M.new_composer_buffer('composer.json')
    if not bufnr then
        return
    end
    local root = M.get_root("json", bufnr)
    local query = ts.query.parse(
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
        local prefix = ts.get_node_text(captures[2], bufnr)
        local source = ts.get_node_text(captures[3], bufnr)

        local prefixc = prefix:gsub("%\\", "")
        local sourcec = source:gsub("/", "")

        composer:insert(1, prefixc)
        composer:insert(2, sourcec)
        composer:insert(3, prefix)
    end
    vim.api.nvim_buf_delete(bufnr, { force = true })

    return composer
end

return M
