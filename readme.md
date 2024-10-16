## Namespace.nvim V2

Neovim Php Namespace Resolver

- Namespace.nvim is a powerful Neovim plugin for PHP namespace resolution.

[![asciicast](https://asciinema.org/a/558130.svg)](https://asciinema.org/a/558130)

## Basic Usage

- `:Php classes`: Find all classes, traits, implementations, and attributes from Composer or local search.
- `:Php class`: Get the class under the cursor.
- `:Php namespace`: Generate namespace for the current file.
- `:Php sort`: Sorts namespaces in current file with 6 options.



## Install

```lua

{  -- lazy
    'ccaglak/namespace.nvim',
    keys = {
        { "<leader>la", "<cmd>Php classes<cr>"},
        { "<leader>lc", "<cmd>Php class<cr>"},
        { "<leader>ln", "<cmd>Php namespace<cr>"},
        { "<leader>ls", "<cmd>Php sort<cr>"},
    },
    dependencies = {
        "ccaglak/phptools.nvim", -- optional
        "ccaglak/larago.nvim", -- optional
    }
    config = function()
    require('namespace').setup({
      ui = true, -- default: true -- false only if you want to use your own ui
      cacheOnload = false, -- default: false -- cache composer.json on load
      dumpOnload = false, -- default: false -- dump composer.json on load
      sort = {
        on_save = false, -- default: false -- sorts on every search
        sort_type = 'length_desc', -- default: natural -- seam like what pint is sorting
        --  ascending -- descending -- length_asc
        -- length_desc -- natural -- case_insensitive
      }
    })
    end
}

## Keymaps -- No default keymaps

```vim
    vim.keymap.set("n", "<leader>la", "<cmd>Php classes<cr>", {desc="GetClasses", silent = true})
    vim.keymap.set("n", "<leader>lc", "<cmd>Php class<cr>", {desc="GetClass",silent = true})
    vim.keymap.set("n", "<leader>ln", "<cmd>Php namespace<cr>", {desc="Namespace",silent = true})
    vim.keymap.set("n", "<leader>ls", "<cmd>Php sort<cr>", {desc="Sort Classes",silent = true})
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
