local api = vim.api
local lsp_util = vim.lsp.util

local UI = {}

function UI.select(items, opts, on_choice)
  if #items == 0 then
    vim.notify("No items to select from", vim.log.levels.WARN)
    on_choice(nil)
    return
  end

  local choices = vim.tbl_map(opts.format_item, items)
  local longest_item = math.max(unpack(vim.tbl_map(function(choice) return #choice end, choices)))

  local selected_items = {}

  vim.schedule(function()
    local bufnr, winnr = lsp_util.open_floating_preview(choices, "", {
      border = "rounded",
      title = opts.prompt,
      title_pos = "center",
    })

    api.nvim_win_set_config(winnr, {
      width = longest_item + 4,
    })

    api.nvim_set_current_win(winnr)

    vim.keymap.set("n", "<Space>", function()
      local index = vim.fn.line(".")
      if selected_items[index] then
        selected_items[index] = nil
      else
        selected_items[index] = items[index]
      end
      -- Highlight selected items
      vim.api.nvim_buf_clear_namespace(bufnr, -1, 0, -1)
      for i, _ in pairs(selected_items) do
        vim.api.nvim_buf_add_highlight(bufnr, -1, "Visual", i - 1, 0, -1)
      end
    end, { buffer = bufnr })

    vim.keymap.set("n", "<CR>", function()
      api.nvim_win_close(winnr, true)
      if next(selected_items) then
        on_choice(vim.tbl_values(selected_items))
      else
        local selected_index = vim.fn.line(".")
        on_choice(items[selected_index])
      end
    end, { buffer = bufnr })

    vim.keymap.set("n", "q", function()
      api.nvim_win_close(winnr, true)
      on_choice(nil)
    end, { buffer = bufnr })
  end)
end

return UI
