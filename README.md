# slowreader.nvim

A Neovim plugin that reveals text like a typewriter, one character at a time — perfect for immersive reading sessions or demos.

Thank you for considering supporting this project! Your generosity helps keep development active and ensures the plugin continues to improve.

[![Buy Me A Coffee](https://img.shields.io/badge/-Buy%20me%20a%20coffee-yellow?style=for-the-badge&logo=buy-me-a-coffee&logoColor=white)](https://www.buymeacoffee.com/walkingshamrock)

## Features

- Typing animation per character
- Line numbers and visual distractions hidden during animation
- ESC to interrupt and restore view
- Works with `snacks.nvim` (auto disables & restores `snacks.words`)
- Lazy-loadable with `:SlowRead` command

## Installation (Lazy.nvim)

```lua
{
  "walkingshamrock/slowreader.nvim",
  cmd = { "SlowRead", "SlowInsert" },
  config = function()
    require("slowreader").setup({
      delay = 150, -- Customize typing speed
    })
  end,
}
```

## Usage

```vim
:SlowRead path/to/your/file.txt
```

Or with no argument to animate the current buffer:

```vim
:SlowRead
```

## Additional Commands

### `:SlowInsert`

This command animates text insertion in the current buffer, revealing it one character at a time. Ideal for creating dramatic text effects or for presentations.
