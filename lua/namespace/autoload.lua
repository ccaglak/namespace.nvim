local M = {}
local main = require("namespace.main")

local function has_composer_json()
  local workspace_root = vim.uv.cwd()
  local composer_json_path = workspace_root .. "/composer.json"
  return vim.fn.filereadable(composer_json_path) == 1
end

M.run_composer_dump_autoload = function()
  if not has_composer_json() then
    vim.notify("'composer.json' not found ", vim.log.levels.INFO, { title = "PhpNamespace" })
  end
  local function on_exit(code, signal)
    if code == 0 then
      vim.notify("Composer dump-autoload completed successfully", vim.log.levels.INFO, { title = "PhpNamespace" })
    else
      vim.notify(
        "Composer dump-autoload failed with exit code: " .. code,
        vim.log.levels.ERROR,
        { title = "PhpNamespace" }
      )
    end
  end

  vim.fn.jobstart("composer dump-autoload -o", {
    cwd = vim.fs.workspace_root(0, { "composer.json", ".git", "vendor" }),
    on_exit = on_exit,
  })
end

-- Add this function to run composer dump-autoload when LSP is loaded
M.setup_lsp_autoload = function()
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and client.name == "intelephense" or client.name == "phpactor" then
        main.run_composer_dump_autoload()
      end
    end,
  })
end

M.setup_cache = function()
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and client.name == "intelephense" or client.name == "phpactor" then
        main.read_composer_file()
        main.async_search_files("*.php", function() end)
      end
    end,
  })
end

return M
