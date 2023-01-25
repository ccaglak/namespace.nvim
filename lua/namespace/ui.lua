local popup = require('plenary.popup')
local List = require("plenary.collections.py_list")

local M = {}
local win, opts = nil, nil
local buf_nr
local function close_popup()
    vim.api.nvim_win_close(win, true)
end

local selected = List({})
function M.popup(results)
    selected = results
    buf_nr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf_nr, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf_nr, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf_nr, 'filetype', "Namespace")
    vim.api.nvim_buf_set_lines(buf_nr, 0, -1, true, { results:unpack() })
    -- modifiable at first, then set readonly
    vim.api.nvim_buf_set_option(buf_nr, 'modifiable', false)
    local width = 60
    local height = 10
    local borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }
    local title = "PHPNamespace"

    win, opts = popup.create(buf_nr, {
        line = math.floor(((vim.o.lines - height) / 2) - 1),
        col = math.floor((vim.o.columns - width) / 2),
        minwidth = width,
        minheight = height,
        title = title,
        cursorline = true,
        focusable = true,
        borderchars = borderchars,
    })
    vim.api.nvim_win_set_option(win, "number", true)
    vim.api.nvim_win_set_option(win, 'wrap', false)
    vim.api.nvim_buf_set_option(buf_nr, "bufhidden", "delete")
    vim.api.nvim_buf_set_option(buf_nr, 'modifiable', false)
    vim.api.nvim_buf_set_keymap(
        buf_nr,
        'n',
        'q',
        ':q!<cr>',
        { noremap = true, silent = true }
    )
    vim.api.nvim_buf_set_keymap(
        buf_nr,
        "n",
        "<cr>",
        "<cmd>lua require('namespace.ui').selectItem()<cr>",
        {}
    )
end

local idx = nil
function M.selectItem()
    idx = vim.fn.line(".")
    local selectedline = selected[idx]
    selectedline = selectedline:gsub("%\\\\", "\\")
    selectedline = "use " .. selectedline .. ";"
    close_popup()
    selected = List({})
    require("namespace.getClass").addToBuffer(selectedline)
end

return M
