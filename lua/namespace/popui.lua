local popup = require("plenary.popup")
local List = require("plenary.collections.py_list")
local bf = require("namespace.buffer")

local M = {}
local popup_atts = {} -- stores popup buffer, winid
local namespaces = {}
local mbufnr -- main (current) buffer

local done = true
function M.popup(ret_namespaces, buf)
    mbufnr = buf
    if #ret_namespaces == 1 then
        table.insert(namespaces, unpack(ret_namespaces))
        M.pop(unpack(ret_namespaces))
        return
    end
    local timer = vim.loop.new_timer()
    local co = coroutine.create(function()
            for i, cls in pairs(ret_namespaces) do
                table.insert(namespaces, cls)
                coroutine.yield(M.pop(cls))
                if i == #ret_namespaces then
                    timer:close()
                end
            end
        end)

    timer:start(500, 250, vim.schedule_wrap(function()
        if done == true then
            coroutine.resume(co)
        end
    end))
    -- timer:close() -- Always close handles to avoid leaks.
end

function M.pop(rnamespaces)
    done = false
    local buf_nr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf_nr, "filetype", "Namespace")
    vim.api.nvim_buf_set_lines(buf_nr, 0, -1, true, rnamespaces)
    vim.api.nvim_buf_set_option(buf_nr, "modifiable", false)
    local width = 60
    local height = 10
    local borderchars =
    { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }

    local title = "PHPNamespace"

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
    vim.api.nvim_win_set_option(win, "wrap", false)
    vim.api.nvim_buf_set_keymap(
        buf_nr,
        "n",
        "q",
        ":q!<cr>",
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
    pt = ""
    bf.add_to_buffer(selectedline, mbufnr)
end

-- get the tables first buffer win delete that -- popups stack on top therefore getting the last
M.close_popup = function()
    local pt = table.remove(popup_atts, #popup_atts)
    vim.api.nvim_win_close(pt[2], true)
    vim.api.nvim_buf_delete(pt[1], { force = true })
    done = true
end

return M
