local ensure_install = function(plugin)
  local base_dir = os.getenv("BASE_DIR") or "/tmp/"
  -- local base_dir = os.getenv("BASE_DIR") or "/Users/oguz/.local/share/nvim/lazy/"
  local plugin_name = vim.split(plugin, "/")[2]

  local plugin_dir = base_dir .. plugin_name

  local plugin_not_exists = vim.fn.isdirectory(plugin_dir) == 0
  if plugin_not_exists then
    print("[INFO] Installing " .. plugin_name)
    vim.fn.system({ "git", "clone", "https://github.com/" .. plugin, plugin_dir })
  end

  vim.opt.runtimepath:append(plugin_dir)
end

ensure_install("nvim-lua/plenary.nvim")
ensure_install("nvim-treesitter/nvim-treesitter")
if not require("nvim-treesitter.parsers").has_parser("php") then
  require("nvim-treesitter.install").commands.TSInstallSync["run"]("php")
end

vim.cmd("runtime plugin/plenary.vim")
