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

## Configuration Options

You can customize the behavior of `slowreader.nvim` by passing the following options to the `setup` function:

- `delay` (number): Controls the typing speed in milliseconds. Default is `200`.
- `stop_key` (string): Keybinding to stop the animation. Default is `<Esc>`.
- `initial_delay` (number): Delay in milliseconds before the animation starts. Default is `0`.
- `final_delay` (number): Delay in milliseconds after the animation ends. Default is `0`.
- `scroll_margin` (number): Number of lines to keep the cursor within the visible area. Default is `5`.
- `top_margin` (number): Number of empty lines to add at the top of the buffer. Default is `0`.

Example configuration:

```lua
require("slowreader").setup({
  delay = 150, -- Customize typing speed
  stop_key = "<C-c>", -- Change stop key to Ctrl+C
  initial_delay = 100, -- Add a delay before animation starts
  final_delay = 500, -- Add a delay after animation ends
  scroll_margin = 3, -- Adjust scroll margin
  top_margin = 2, -- Add top margin
})
```

## Contributing

Contributions are welcome! If you have ideas, bug reports, or improvements, feel free to open an issue or submit a pull request. Let's make `slowreader.nvim` even better together!
