local M = {}

local notify = require("namespace.notify").notify
local ns = require("namespace.composer")

local project_root = vim.fs.root(0, { ".git" }) or vim.uv.cwd()

local function has_composer_json()
  local composer_json_path = project_root .. "/composer.json"
  return vim.fn.filereadable(composer_json_path) == 1
end

M.run_composer_dump_autoload = function()
  vim.fn.chdir(project_root)

  if not has_composer_json() then
    notify("'composer.json' not found ")
    return
  end

  local function on_exit(job_id, exit_code, event_type)
    if exit_code == 0 then
      notify("Composer dump-autoload completed successfully")
    else
      local output = vim.fn.join(vim.fn.jobread(job_id), "\n")
      notify("Composer dump-autoload failed")
    end
  end

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
        local project_root = vim.fs.root(0, { "git", "composer.json" })
        vim.fn.chdir(project_root)
        M.run_composer_dump_autoload()
      end
    end,
    once = true,
  })
end

M.setup_cache = function()
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and client.name == "intelephense" or client.name == "phpactor" then
        ns.read_composer_file()
      end
    end,
    once = true,
  })
end

return M
