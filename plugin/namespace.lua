vim.api.nvim_create_user_command("GetAllClasses", require("namespace").getAllClasses, {})
vim.api.nvim_create_user_command("GetClass", require("namespace").getClass, {})
vim.api.nvim_create_user_command("SortClass", require("namespace.sort").sort, {})
