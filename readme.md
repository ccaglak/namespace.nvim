## Namespace.nvim

Neovim Php Namespace Resolver

- Feels better then intelephense & phpactor features

[![asciicast](https://asciinema.org/a/558130.svg)](https://asciinema.org/a/558130)

## Basic Usage

-   `:GetAllClasses` or `GetClasses` Finds all classes, traits, implementations, attributes, from composer or from local search
-   `:GetClass` gets class under cursor
-   `:AsClass` class As -- gets class under cursor or on empty
-   `:Namespace` generates namespace

-   `:SortClass` Depricated -- pass it on to formatters

## Install

```lua

{  -- lazy
    'ccaglak/namespace.nvim',
    keys = {
        { "<leader>la", "<cmd>GetClasses<cr>"},
        { "<leader>lc", "<cmd>GetClass<cr>"},
        { "<leader>ls", "<cmd>AsClass<cr>"},
        { "<leader>ln", "<cmd>Namespace<cr>"},
    }
    dependencies = {
        "nvim-lua/plenary.nvim"
    }
}

```

## Keymaps -- No default keymaps

```vim
    vim.keymap.set("n", "<leader>la", "<cmd>GetClasses<cr>")
    vim.keymap.set("n", "<leader>lc", "<cmd>GetClass<cr>")
    vim.keymap.set("n", "<leader>ls", "<cmd>AsClass<cr>")
    vim.keymap.set("n", "<leader>ln", "<cmd>Namespace<cr>")
```

## Requires

-   pleanery.nvim
-   nvim-treesitter (`:TSInstall php json`)
-   brew install ripgrep

## Features to be add
    -- needs to be cleanup/refactored
    -- add missing method/class etc

## Known bugs
-   no known bugs
-   Let me know if you have any edge cases

## Check Out

Laravel Goto Blade/Components [larago.nvim](https://github.com/ccaglak/larago.nvim).


## Inspired

-   by VSCode Php Namespace Resolver

## License MIT
