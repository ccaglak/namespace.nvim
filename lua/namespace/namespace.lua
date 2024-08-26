-- Namespace generator
local root           = require("namespace.root")
local M              = {}

M.composer           = function()
    local cf = M.composer_file_load()
    if cf == nil then
        return
    end

    local auto = cf.autoload["psr-4"]
    for index, value in pairs(auto) do -- Todo multiple
        return index, value
    end
end

M.composer_file_load = function()
    if M.cmpsr then
        return M.cmpsr
    end

    local composer = vim.uv.cwd() .. "/composer.json"
    local exists = vim.uv.fs_stat(composer)
    if not exists then
        return
    end

    local content = vim.fn.readfile(composer)

    M.cmpsr = vim.fn.json_decode(content)
    return M.cmpsr
end

function string.pascalcase(str, deli)
    deli = deli or "\\"
    local pascalCase = ""
    for match in str:gmatch("[a-zA-Z0-9]+") do
        pascalCase = pascalCase .. match:gsub("^.", string.upper) .. deli
    end
    return pascalCase:sub(1, -2)
end

function io.pathinfo(path)
    local pos = string.len(path)
    local extpos = pos + 1
    while pos > 0 do
        local b = string.byte(path, pos)
        if b == 46 then     -- 46 = char "."
            extpos = pos
        elseif b == 47 then -- 47 = char "/"
            break
        end
        pos = pos - 1
    end

    local dirname = string.sub(path, 1, pos)
    local filename = string.sub(path, pos + 1)
    extpos = extpos - pos
    local basename = string.sub(filename, 1, extpos - 1)
    local extname = string.sub(filename, extpos)
    return {
        dirname = dirname,
        filename = filename,
        basename = basename,
        extname = extname,
    }
end

function M.run()
    local filename = vim.api.nvim_buf_get_name(0)
    local pathinfo = io.pathinfo(filename)
    local dir = pathinfo.dirname:gsub(root.root(), "")
    if dir == "" then
        return
    end
    local prefix, src = M.composer()
    local ns = M.gen(dir, prefix, src) -- Todo just in case src is dirty
    M.add_to_current_buffer({ ns })
end

function M.gen(dir, prefix, src, filename)
    --
    dir = dir:gsub(src, prefix)
    local ns = string.pascalcase(dir)

    if filename ~= nil then
        return "use " .. ns .. "\\" .. filename .. ";"
    end

    return "namespace " .. ns .. ";"
end

function M.add_to_current_buffer(lines)
    local insertion_line = M.get_insertion_point() - 1
    vim.api.nvim_buf_set_lines(0, insertion_line, insertion_line, true, lines)
    vim.api.nvim_buf_call(0, function()
        vim.cmd("silent! write! | edit")
    end)
end

function M.get_insertion_point()
    -- local lastline = vim.api.nvim_buf_line_count(bufnr)
    -- TODO dont want to read whole file 1/4
    local content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local insertion_point = nil

    for i, line in ipairs(content) do
        if line:find("^declare") or line:find("^namespace") or line:find("^use") then
            insertion_point = i
        end

        if
            line:find("^class")
            or line:find("^final")
            or line:find("^interface")
            or line:find("^abstract")
            or line:find("^trait")
            or line:find("^enum")
        then
            break
        end
    end

    return insertion_point or 3
end

return M
