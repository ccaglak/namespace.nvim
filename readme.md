## Namespace.nvim

Neovim Php Namespace Resolver - tested on mac

[![asciicast](https://asciinema.org/a/kqXkcSyzRJqU4or9lhLVoaxXq.svg)](https://asciinema.org/a/kqXkcSyzRJqU4or9lhLVoaxXq)

## Install

```lua

{
    'ccaglak/namespace.nvim',
    dependencies = {
        "nvim-lua/plenary.nvim"
    }
}

```

## Keymaps -- plugin doesn't set any keymaps

```vim
    vim.keymap.set("n", "<leader>la", "<cmd>GetAllClasses<cr>")
    vim.keymap.set("n", "<leader>lc", "<cmd>GetClass<cr>")
    vim.keymap.set("n", "<leader>ls", "<cmd>SortClass<cr>")
```

## Requires

-   pleanery.nvim
-   brew install ripgrep

## Basic Usage

-   `:GetAllClasses` Finds all classes

-   `:GetClass` gets class under cursor

-   `:SortClass` sorts classes

## Features to be add

-   AutoNamespace generator

-   add options to sort, currently length

## Known bugs

-   imports current file class -- easy fix

## Check Out

Laravel Goto Blade/Components [larago.nvim](https://github.com/ccaglak/larago.nvim).


## Inspired

-   by VSCode Php Namespace Resolver

## License MIT
