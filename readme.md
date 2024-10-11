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
        { "<leader>ls", "<cmd>Php classes<cr>"},
        { "<leader>lc", "<cmd>Php class<cr>"},
        { "<leader>ln", "<cmd>Php namespace<cr>"},
    },
    dependencies = {
        "nvim-lua/plenary.nvim",
        "ccaglak/phptools.nvim", -- optional
        "ccaglak/larago.nvim", -- optional
    }
    config = function()
    require('namespace').setup({
      ui = false, -- default: false
      cacheOnload = false, -- default: false
      dumpOnload = false, -- default: false
      sort = {
        enable = false, -- default: false
        on_save = false, -- default: false
        sort_type = 'length_desc', -- default: natural
        --  ascending -- descending -- length_asc
        -- length_desc -- natural -- case_insensitive
      }
    })
    end
}

## Keymaps -- No default keymaps

```vim
    vim.keymap.set("n", "<leader>la", "<cmd>Php classes<cr>")
    vim.keymap.set("n", "<leader>lc", "<cmd>Php class<cr>")
    vim.keymap.set("n", "<leader>ln", "<cmd>Php namespace<cr>")
```

## Requires

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
