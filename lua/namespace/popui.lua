local popup = require("plenary.popup")
local bf = require("namespace.buffer")
local List = require("plenary.collections.py_list")

local M = {}
local popup_atts = {} -- stores popup buffer, winid
local namespaces = {}
local mbufnr          -- main (current) buffer

M.asRequired = false

local done = true
function M.popup(ret_namespaces, buf, asbool)
    M.asRequired = asbool or false
    mbufnr = buf
    if #ret_namespaces == 1 then
        table.insert(namespaces, unpack(ret_namespaces))
        M.pop(unpack(ret_namespaces))
        return
    end
    local timer = vim.uv.new_timer()
    local co = coroutine.create(function()
        for i, cls in pairs(ret_namespaces) do
            table.insert(namespaces, cls)
            coroutine.yield(M.pop(cls))
            if i == #ret_namespaces then
                timer:close()
            end
        end
    end)

    timer:start(
        500,
        250,
        vim.schedule_wrap(function()
            if done == true then
                coroutine.resume(co)
            end
        end)
    )
end

function M.pop(rnamespaces)
    done = false
    local buf_nr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value("filetype", "Namespace", { buf = buf_nr })
    vim.api.nvim_buf_set_lines(buf_nr, 0, -1, true, rnamespaces)
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf_nr })
    local width = 60
    local height = 10
    local borderchars =
    { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }

    local win, _ = popup.create(buf_nr, {
        line = math.floor(((vim.o.lines - height) / 2) - 1),
        col = math.floor((vim.o.columns - width) / 2),
        minwidth = width,
        minheight = height,
        title = "PHPNamespace",
        cursorline = true,
        focusable = true,
        borderchars = borderchars,
    })

    table.insert(popup_atts, { buf_nr, win })
    vim.api.nvim_set_option_value("number", true, { win = win })
    vim.api.nvim_set_option_value("wrap", false, { win = win })
    vim.api.nvim_buf_set_keymap(
        buf_nr,
        "n",
        "q",
        "<cmd>lua require('namespace.popui').close_popup()<cr>",
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

M.select_item = function()
    local pt = table.remove(namespaces, #namespaces)
    local id = vim.fn.line(".")

    M.close_popup()
    local selectedline = pt[id]

    if M.asRequired == true then
        require("namespace.classAs").input(List({ selectedline }))
        return
    end
    selectedline = "use " .. selectedline .. ";"

    pt = ""
    bf.add_to_buffer(selectedline, mbufnr)
end

M.close_popup = function()
    local pt = table.remove(popup_atts, #popup_atts)
    vim.api.nvim_win_close(pt[2], true)
    vim.api.nvim_buf_delete(pt[1], { force = true })
    done = true
end

return M
