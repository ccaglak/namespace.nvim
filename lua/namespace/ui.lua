local api = vim.api
local lsp_util = vim.lsp.util

local ui = {}

local function esc(cmd)
  return api.nvim_replace_termcodes(cmd, true, false, true)
end

local function get_win_width(value_length, opts)
  return math.max(value_length + 10, (opts.prompt and opts.prompt:len() + 10 or 0))
end

vim.ui.select = function(items, opts, on_choice)
  opts = opts or {}
  local choices = {}
  local format_item = opts.format_item or tostring
  local longest_item = 0
  for i, item in ipairs(items) do
    local choice = table.concat({ tostring(i), ". ", format_item(item), " " })
    table.insert(choices, choice)
    longest_item = math.max(longest_item, #choice)
  end

  local bufnr, winnr = lsp_util.open_floating_preview(choices, "", {
    border = "rounded",
    title = opts.prompt,
    title_pos = "center",
  })

  api.nvim_win_set_config(winnr, {
    width = get_win_width(longest_item, opts),
  })

  api.nvim_set_current_win(winnr)
  vim.keymap.set("n", "<CR>", function()
    local item = items[vim.fn.line(".")]
    api.nvim_win_close(0, true)
    if item then
      on_choice(item, vim.fn.line("."))
    else
      on_choice(nil, nil)
    end
  end, { buffer = bufnr })
end

vim.ui.input = function(opts, on_confirm)
  opts = opts or {}
  local current_val = opts.default or ""
  local win_width = get_win_width(#current_val, opts)
  local bufnr, winnr = lsp_util.open_floating_preview({ current_val }, "", {
    height = 1,
    border = "rounded",
    width = win_width,
    wrap = false,
    title = opts.prompt,
    title_pos = "center",
  })

  api.nvim_win_set_config(winnr, { width = win_width })
  api.nvim_set_current_win(winnr)
  api.nvim_buf_set_option(bufnr, "modifiable", true)
  vim.keymap.set("i", "<CR>", function()
    local input = vim.trim(vim.fn.getline("."))
    api.nvim_win_close(0, true)
    api.nvim_feedkeys(esc("<Esc>"), "i", true)
    on_confirm(#input > 0 and input or nil)
  end, { buffer = bufnr })
  vim.cmd.startinsert({ bang = true })
end

return ui
