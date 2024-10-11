---@class Config
---@field opt string Your config option
local config = {
  ui = false,
  cacheOnload = false,
  dumpOnload = false,
  sort = {
    enabled = false,
    on_save = false,
    sort_type = "natural",
  },
}

---@class Namespace
local M = {}

---@type Config
M.config = config

---@param args Config?
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
  if M.config.ui == true then
    require("namespace.ui")
  end
  if M.config.cacheOnload == true then
    require("namespace.autoload").setup_cache()
  end
  if M.config.dumpOnload == true then
    require("namespace.autoload").run_composer_dump_autoload()
  end
end

M.classes = function()
  return require("namespace.main").getClasses()
end

M.class = function()
  return require("namespace.main").getClass()
end

M.namespace = function()
  require("namespace.composer").resolve()
end

M.sort = function()
  dd(M.config.sort)
  if M.config.sort.enabled then
    require("namespace.sort").sortUseStatements(M.config.sort)
  else
    vim.notify("Sort is disabled ", vim.log.levels.WARN, { title = "PhpNamespace" })
  end
end

return M
