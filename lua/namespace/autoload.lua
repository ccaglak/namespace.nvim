local M = {}
local main = require("namespace.main")
local ns = require("namespace.composer")

local function has_composer_json()
  local workspace_root = vim.fs.root(0, { "composer.json", ".git", "vendor" })
  local composer_json_path = workspace_root .. "/composer.json"
  return vim.fn.filereadable(composer_json_path) == 1
end

M.run_composer_dump_autoload = function()
  if not has_composer_json() then
    vim.notify("'composer.json' not found ", vim.log.levels.INFO, { title = "PhpNamespace" })
  end
  local function on_exit(job_id, exit_code, event_type)
    if exit_code == 0 then
      vim.notify("Composer dump-autoload completed successfully", vim.log.levels.INFO, { title = "PhpNamespace" })
    else
      local output = vim.fn.join(vim.fn.jobread(job_id), "\n")
      vim.notify(
        string.format("Composer dump-autoload failed with exit code: %d\nOutput: %s", exit_code, output),
        vim.log.levels.ERROR,
        { title = "PhpNamespace" }
      )
    end
  end
  local project_root = vim.fs.root(0, { "composer.json", ".git", "vendor" })
  vim.fn.chdir(project_root)

  vim.fn.jobstart({ "composer", "dump-autoload", "-o" }, {
    cwd = project_root,
    on_exit = on_exit,
  })
end

-- Add this function to run composer dump-autoload when LSP is loaded
M.setup_lsp_autoload = function()
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and client.name == "intelephense" or client.name == "phpactor" then
        local project_root = vim.fs.root(0, { "composer.json", ".git", "vendor" })
        vim.fn.chdir(project_root)
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
        ns.read_composer_file()
        main.search("*.php", function() end)
      end
    end,
  })
end

return M
