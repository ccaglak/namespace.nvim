## Namespace.nvim V2 #BETA

Neovim Php Namespace Resolver

- Namespace.nvim is a powerful Neovim plugin for PHP namespace resolution.

[![asciicast](https://asciinema.org/a/558130.svg)](https://asciinema.org/a/558130)

## Basic Usage

- `:Php classes`: Find all classes, traits, implementations, and attributes from Composer or local search.
- `:Php class`: Get the class under the cursor.
- `:Php namespace`: Generate namespace for the current file.


## Install

```lua

{  -- lazy
    'ccaglak/namespace.nvim',
    keys = {
        { "<leader>la", "<cmd>Php classes<cr>"},
        { "<leader>lc", "<cmd>Php class<cr>"},
        { "<leader>ln", "<cmd>Php namespace<cr>"},
    },
    dependencies = {
        "nvim-lua/plenary.nvim"
    }
}

## Keymaps -- No default keymaps

```vim
    vim.keymap.set("n", "<leader>la", "<cmd>Php classes<cr>")
    vim.keymap.set("n", "<leader>lc", "<cmd>Php class<cr>")
    vim.keymap.set("n", "<leader>ln", "<cmd>Php namespace<cr>")
```

## Requires

-   pleanery.nvim
-   nvim-treesitter (`:TSInstall php json`)
-   brew install ripgrep

## Known bugs
-   no known bugs

## Check Out

- PhpTools [phptools.nvim](https://github.com/ccaglak/phptools.nvim).
- Laravel Goto Blade/Components [larago.nvim](https://github.com/ccaglak/larago.nvim).


## Inspired

-   by VSCode Php Namespace Resolver

## License MIT
