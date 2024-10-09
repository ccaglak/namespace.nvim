local plenary_dir = os.getenv("PLENARY_DIR") or "/tmp/plenary.nvim"
local is_not_a_directory = vim.fn.isdirectory(plenary_dir) == 0
if is_not_a_directory then
  vim.fn.system({ "git", "clone", "https://github.com/nvim-lua/plenary.nvim", plenary_dir })
end

vim.opt.rtp:append(".")
vim.opt.rtp:append(plenary_dir)
local treesitter_dir = "~/.local/share/nvim/lazy/nvim-treesitter"
vim.opt.rtp:append(treesitter_dir)

vim.cmd("runtime plugin/plenary.vim")
require("plenary.busted")
require("nvim-treesitter.query_predicates")
-- local mock = require("luassert.mock")
-- local stub = require("luassert.stub")

_G.dd = function(v)
  print(vim.inspect(v))
  return v
end
