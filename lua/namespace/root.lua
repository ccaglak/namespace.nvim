local M = {}
M.getRoot = function(language, bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local parser = vim.treesitter.get_parser(bufnr, language, {})
    local tree = parser:parse()[1]
    return tree:root(), bufnr
end

return M
