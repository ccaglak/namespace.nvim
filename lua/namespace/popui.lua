local popup = require('plenary.popup')
local List  = require("plenary.collections.py_list")
local bf    = require("namespace.buffer")
local utils = require('namespace.utils')

local M = {}
local popup_atts = {} -- stores popup buffer, winid
local namespaces = {}
local mbufnr -- main (current) buffer -- because of popups it interferes

function M.popup(ret_namespaces, buf)
    mbufnr = buf
    local rnamespaces = { ret_namespaces:unpack() }
    table.insert(namespaces, rnamespaces)
    M.pop(rnamespaces)
end

function M.pop(rnamespaces)
    local buf_nr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf_nr, 'filetype', "Namespace")
    vim.api.nvim_buf_set_lines(buf_nr, 0, -1, true, rnamespaces)
    vim.api.nvim_buf_set_option(buf_nr, 'modifiable', false)
    local width = 60
    local height = 10
    local borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }

    local ns = utils.spliter(rnamespaces[1],'\\')  -- namespace name 

    local title = "PHPNamespace | " .. ns[#ns].. " |"-- add the namespace

    local win, _ = popup.create(buf_nr, {
        line = math.floor(((vim.o.lines - height) / 2) - 1),
        col = math.floor((vim.o.columns - width) / 2),
        minwidth = width,
        minheight = height,
        title = title,
        cursorline = true,
        focusable = true,
        borderchars = borderchars,
    })
    table.insert(popup_atts, { buf_nr, win })
    vim.api.nvim_win_set_option(win, "number", true)
    vim.api.nvim_win_set_option(win, 'wrap', false)
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
        "<cmd>lua require('namespace.popui').select_item()<cr>",
        {}
    )
end

function M.select_item()
    local pt = table.remove(namespaces, #namespaces)
    local id = vim.fn.line(".")

    M.close_popup()
    local selectedline = pt[id]

    selectedline = selectedline:gsub("%\\\\", "\\")
    selectedline = "use " .. selectedline .. ";"
    pt = ''
    bf.add_to_buffer(selectedline, mbufnr)
end

-- get the tables first buffer win delete that -- popups stack on top therefore getting the last
M.close_popup = function()
    local pt = table.remove(popup_atts, #popup_atts)
    vim.api.nvim_win_close(pt[2], true)
    vim.api.nvim_buf_delete(pt[1], { force = true })
end

return M
