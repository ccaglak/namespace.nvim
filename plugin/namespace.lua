local nvim_create_user_command = vim.api.nvim_create_user_command
nvim_create_user_command(
    "GetAllClasses",
    require("namespace").get_classes,
    {}
)
nvim_create_user_command(
    "GetClasses",
    require("namespace").get_classes,
    {}
)
nvim_create_user_command("GetClass", require("namespace").get_class, {})
nvim_create_user_command("AsClass", require("namespace").as_class, {})

nvim_create_user_command(
    "Namespace",
    require("namespace").name_space,
    {}
)

-- Depricated SortClass
nvim_create_user_command(
    "SortClass",
    require("namespace").sort_classes,
    {}
)
