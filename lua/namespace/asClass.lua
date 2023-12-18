local popup = require("plenary.popup")

local List = require("plenary.collections.py_list")
local pop = require("namespace.popui")
local search = require("namespace.search")
local tree = require("namespace.treesitter")
local bf = require("namespace.buffer")

local api = vim.api
local fn = vim.fn

local M = {}

M.open = function(cWord)
    cWord = cWord or vim.fn.escape(vim.fn.expand("<cword>"), [[\/]])
    local bufnr = require("namespace.utils").get_bufnr()

    if cWord == "" then
        vim.defer_fn(function()
            cWord = M.input("")
        end, 10)
        if cWord == "" then
            return
        end
    end
    local sr = search.CSearch(cWord)
    if #sr == 0 then
        local prefix = tree.namespace_prefix()
        sr = search.RSearch(List({ cWord }), prefix)
        if #sr == 0 then
            return
        elseif #sr == 1 then
            M.input(cWord, bufnr, sr)
        elseif #sr > 1 then
            pop.popup({ { sr:unpack() } }, bufnr, true) --requires double brackets to be able check size in popui
        end
        return
    end

    local searched = tree.search_parse(sr) -- return namespace
    if #searched == 1 then
        M.input(cWord, bufnr, searched)
    elseif #searched > 1 then
        pop.popup({ { searched:unpack() } }, bufnr, true) --requires double brackets to be able ch
    end
    searched = List({})
end

M.input = function(cWord, mbufnr, searched)
    local bufnr = api.nvim_create_buf(false, false)

    local width = 60
    local height = 1
    local borderchars =
    { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }

    local _, win = popup.create(bufnr, {
        title = "Namespace",
        highlight = "Normal",
        line = math.floor(((vim.o.lines - height) / 2) - 1),
        col = math.floor((vim.o.columns - width) / 2),
        minwidth = width,
        minheight = height,
        borderchars = borderchars,
    })

    api.nvim_win_set_option(win.border.win_id, "winhl", "Normal:HarpoonBorder")

    api.nvim_buf_set_option(bufnr, "buftype", "prompt")
    api.nvim_buf_set_keymap(
        bufnr,
        "i",
        "<esc>",
        "<cmd>q!<cr><esc>",
        { noremap = true }
    )
    api.nvim_buf_set_keymap(
        bufnr,
        "n",
        "<esc>",
        "<cmd>q!<cr><esc>",
        { noremap = true }
    )

    vim.cmd([[ :startinsert ]])


    if cWord == "" then
        fn.prompt_setprompt(bufnr, string.format("Class Name > "))
        fn.prompt_setcallback(bufnr, function(nn)
            vim.cmd([[ q! ]])
            M.open(nn)
        end)
    else
        fn.prompt_setprompt(bufnr, string.format(" %s to > ", cWord))
        fn.prompt_setcallback(bufnr, function(cn)
            vim.cmd([[ q! ]])
            local line
            if type(cWord) == "table" then
                line = cWord:unpack()
            end
            if type(cWord) == "string" then
                line = searched:unpack()
            end
            line = line:gsub("%\\\\", "\\")
            line = "use " .. line .. " as " .. cn .. ";"
            bf.add_to_buffer(line, mbufnr)
        end)
    end
end


return M
