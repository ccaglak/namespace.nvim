vim.api.nvim_create_user_command("GetAllClasses", require("namespace.getClasses").get, {})
vim.api.nvim_create_user_command("GetClass", require("namespace.getClass").get, {})
vim.api.nvim_create_user_command("SortClass", require("namespace.sort").sort, {})
