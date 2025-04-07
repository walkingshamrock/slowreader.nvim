# slowreader.nvim

A Neovim plugin that reveals text like a typewriter, one character at a time — perfect for immersive reading sessions or demos.

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
  cmd = "SlowRead",
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
