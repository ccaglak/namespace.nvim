## Namespace.nvim

Neovim Php Namespace Resolver
GetAllClasses Doesn't get all classes because cant get the for loop to wait for ui response until i find solution
use GetClass.

## Install

```lua

{'ccaglak/namespace.nvim'}

```

## Keymaps -- plugin doesn't set any keymaps

```
    vim.keymap.set("n", "<leader>la", "<cmd>GetAllClasses<cr>")
    vim.keymap.set("n", "<leader>lc", "<cmd>GetClass<cr>")
    vim.keymap.set("n", "<leader>ls", "<cmd>SortClass<cr>")
```

## Requires

-   pleanery.nvim
-   rg

## Basic Usage

-   `:GetAllClasses` Finds all classes

-   `:GetClass` gets class under cursor

-   `:SortClass` sorts classes

## Features to be add

-   AutoNamespace generator

-   add options to sort, currently length

## Inspired

-   by VSCode Php Namespace Resolver

## License MIT
