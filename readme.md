## Namespace.nvim

Neovim Php Namespace Resolver

## Install

```lua

{'ccaglak/namespace.nvim'}

```

## Keymaps -- plugin doesn't set any keymaps

```
    vim.keymap.set("n", "la", "<cmd>GetAllClasses")
    vim.keymap.set("n", "lc", "<cmd>GetClass")
    vim.keymap.set("n", "ls", "<cmd>SortClass")
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
