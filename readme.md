## Namespace.nvim

Neovim Php Namespace Resolver

- Feels better then intelephense & phpactor features

[![asciicast](https://asciinema.org/a/558130.svg)](https://asciinema.org/a/558130)

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
    vim.keymap.set("n", "<leader>ls", "<cmd>AsClass<cr>")
```

## Requires

-   pleanery.nvim
-   nvim-treesitter (`:TSInstall php`, `:TSInstall json`)
-   brew install ripgrep

## Basic Usage

-   `:GetAllClasses` Finds all classes, traits, implementations, attributes, from composer or local search

-   `:GetClass` gets class under cursor
-   `:AsClass` As classes  -- use Illuminate\Routing\Controller as BaseController;
-   gets class under cursor if it exists and names it or if cant find will seach composer and popup to name it

-   `:SortClass` Depricated -- pass it on to formatters


## Features to be add

-   AutoNamespace generator
-   Option how to sort

## Known bugs
-   no known bugs
-   Let me know if you have any edge cases

## Check Out

Laravel Goto Blade/Components [larago.nvim](https://github.com/ccaglak/larago.nvim).


## Inspired

-   by VSCode Php Namespace Resolver

## License MIT
