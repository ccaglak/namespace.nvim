## Namespace.nvim -only works on latest stable for nightly v11 use branch v2

Neovim Php Namespace Resolver

- Feels better then intelephense & phpactor features

[![asciicast](https://asciinema.org/a/558130.svg)](https://asciinema.org/a/558130)

## Treesitter php updates might break the plugin if plugin doesn't behave as normal report the as issue.

## Basic Usage

-   `:GetClasses` Finds all classes, traits, implementations, attributes, from composer or from local search
-   `:GetClass` gets class under cursor
-   `:ClassAs` class As -- gets class under cursor or on empty
-   `:Namespace` generates namespace

## Install

```lua

{  -- lazy
    'ccaglak/namespace.nvim',
    keys = {
        { "<leader>la", "<cmd>GetClasses<cr>"},
        { "<leader>lc", "<cmd>GetClass<cr>"},
        { "<leader>ls", "<cmd>ClassAs<cr>"},
        { "<leader>ln", "<cmd>Namespace<cr>"},
    },
    dependencies = {
        "nvim-lua/plenary.nvim"
    }
}

```
## if you get "Not an Editor Command" error then use
```lua
 { -- lazy
    ft = { 'php' },
    'ccaglak/namespace.nvim',
    keys = {
        { '<leader>lc', '<cmd>lua require("namespace.getClass").get()<cr>',   { desc = 'GetClass' } },
        { '<leader>la', '<cmd>lua require("namespace.getClasses").get()<cr>', { desc = 'GetClasses' } },
        { "<leader>ls", '<cmd>lua require("namespace.classAs").open()<cr>', { desc = 'ClassAs' } },
        { "<leader>ln", '<cmd>lua require("namespace.namespace").gen()<cr>', { desc = 'Generate Namespace' } },
    },
   dependencies = {
        "nvim-lua/plenary.nvim"
    }
}
```

## Keymaps -- No default keymaps

```vim
    vim.keymap.set("n", "<leader>la", "<cmd>GetClasses<cr>")
    vim.keymap.set("n", "<leader>lc", "<cmd>GetClass<cr>")
    vim.keymap.set("n", "<leader>ls", "<cmd>ClassAs<cr>")
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

- PhpTools [phptools.nvim](https://github.com/ccaglak/phptools.nvim).
- Laravel Goto Blade/Components [larago.nvim](https://github.com/ccaglak/larago.nvim).


## Inspired

-   by VSCode Php Namespace Resolver

## License MIT
