## Namespace.nvim

Neovim Php Namespace Resolver - tested on mac

[![asciicast](https://asciinema.org/a/kqXkcSyzRJqU4or9lhLVoaxXq.svg)](https://asciinema.org/a/kqXkcSyzRJqU4or9lhLVoaxXq)

## Install

```lua

{  -- lazy
    'ccaglak/namespace.nvim',
    dependencies = {
        "nvim-lua/plenary.nvim"
    }
}

```
```lua

{  -- packer
    'ccaglak/namespace.nvim',
    requires = {
        "nvim-lua/plenary.nvim"
    }
}

```

## Keymaps -- No default keymaps

```vim
    vim.keymap.set("n", "<leader>la", "<cmd>GetAllClasses<cr>")
    vim.keymap.set("n", "<leader>lc", "<cmd>GetClass<cr>")
    vim.keymap.set("n", "<leader>ls", "<cmd>SortClass<cr>")
```

## Requires

-   pleanery.nvim
-   nvim-treesitter
-   brew install ripgrep

## Basic Usage

-   `:GetAllClasses` Finds all classes

-   `:GetClass` gets class under cursor

-   `:SortClass` sorts classes

## Features to be add

-   AutoNamespace generator

-   Option how to sort

## Known bugs

-   Let me know if you have any edge cases

## Check Out

Laravel Goto Blade/Components [larago.nvim](https://github.com/ccaglak/larago.nvim).


## Inspired

-   by VSCode Php Namespace Resolver

## License MIT
