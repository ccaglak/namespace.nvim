local M = {}

M.get_bufnr = function(filename)
    filename = filename or vim.api.nvim_buf_get_name(0)
    return vim.fn.bufnr(filename)
end

-- write to the buffer
-- insertion_point for the namespace.lua to bypass insertion_point func
M.add_to_buffer = function(line, bufnr, insertion_point) -- nsb namespace bool - true
    bufnr = bufnr or M.get_bufnr()
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end
    if insertion_point == nil then
        insertion_point = require("namespace.utils").get_insertion_point(bufnr)
    end
    vim.api.nvim_buf_set_lines(bufnr, insertion_point, insertion_point, true, { line })
end
return M
