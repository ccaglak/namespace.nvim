local api = vim.api
local lsp_util = vim.lsp.util

local UI = {}
function UI.select(items, opts, on_choice)
  local choices = {}
  local longest_item = 0

  for _, item in ipairs(items) do
    local choice = opts.format_item(item)
    table.insert(choices, choice)
    longest_item = math.max(longest_item, #choice)
  end

  local bufnr, winnr = lsp_util.open_floating_preview(choices, "", {
    border = "rounded",
    title = opts.prompt,
    title_pos = "center",
  })

  api.nvim_win_set_config(winnr, {
    width = longest_item + 10,
  })

  api.nvim_set_current_win(winnr)
  vim.keymap.set("n", "<CR>", function()
    local selected_index = vim.fn.line(".")
    local selected_item = items[selected_index]
    api.nvim_win_close(winnr, true)
    on_choice(selected_item)
  end, { buffer = bufnr })

  vim.keymap.set("n", "q", function()
    api.nvim_win_close(winnr, true)
    on_choice(nil)
  end, { buffer = bufnr })
end

return UI
