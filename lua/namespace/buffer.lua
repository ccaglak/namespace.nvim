local utils = require("namespace.utils")
local M = {}

M.get_bufnr = function(filename)
    filename = filename or vim.api.nvim_buf_get_name(0)
    local buf_exists = vim.fn.bufexists(filename) ~= 0
    if buf_exists then
        return vim.fn.bufnr(filename)
    end
    return 0
end

M.add_to_buffer = function(line, bufnr)
    bufnr = bufnr or M.get_bufnr()
    local insertion_point = utils.get_insertion_point()
    vim.api.nvim_buf_set_lines(bufnr, insertion_point, insertion_point, true, { line })
    vim.api.nvim_echo({ { "Lines Added", 'Function' }, { ' ' .. 1 } }, true, {})
end
return M
