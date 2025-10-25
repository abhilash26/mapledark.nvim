 🍁 Maple Dark for Neovim

A colorful dark theme with medium brightness and low saturation, designed for comfortable long coding sessions.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Neovim](https://img.shields.io/badge/neovim-0.9%2B-green.svg)

Inspired by the [VS Code Maple Theme](https://github.com/subframe7536/vscode-theme-maple).

## ✨ Features

- 🎨 **Carefully crafted color palette** with medium brightness and low saturation
- 🌙 **Dark background** optimized for reduced eye strain
- 🔤 **Semantic syntax highlighting** with distinct colors for different code elements
- 🔧 **Full Treesitter support** for modern syntax highlighting
- 📦 **LSP integration** with semantic tokens and diagnostics
- 🎯 **Plugin support** for popular Neovim plugins:
  - blink.cmp
  - fzf-lua
  - oil.nvim
  - conform.nvim
  - lazy.nvim
  - mason.nvim
  - gitsigns.nvim
  - telescope.nvim (fallback)
  - which-key.nvim
  - notify.nvim
  - mini.nvim
  - noice.nvim

## 📦 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'abhilash26/mapledark.nvim',
  lazy = false,
  priority = 1000,
  config = function()
    vim.cmd.colorscheme('mapledark')
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'abhilash26/mapledark.nvim',
  config = function()
    vim.cmd.colorscheme('mapledark')
  end
}
```

### Using Vim-Plug

```vim
Plug 'abhilash26/mapledark.nvim'
```

Then in your `init.vim` or `init.lua`:

```vim
colorscheme mapledark
```

## 🎨 Color Palette

### Background Colors
- `#1a1a1b` - Main background (darker)
- `#1e1e1f` - Secondary background
- `#2a2a2b` - Selection background
- `#333333` - Lighter background (popups, statusline)

### Foreground Colors
- `#cbd5e1` - Main foreground
- `#f3f2f2` - Lighter foreground
- `#787c99` - Darker foreground (comments, line numbers)

### Semantic Colors
- 🔴 `#edabab` - Red (errors, exceptions)
- 🟠 `#eecfa0` - Orange (warnings, constants)
- 🟡 `#ffe8b9` - Yellow (types, classes)
- 🟢 `#a4dfae` - Green (strings, success)
- 🔵 `#8fc7ff` - Blue (functions, info)
- 🟣 `#d2ccff` - Magenta (keywords, statements)
- 🩵 `#a1e8e5` - Cyan (special, modules)
- ⚡ `#bafffe` - Accent (punctuation, delimiters)

## 🚀 Usage

After installation, activate the theme:

### Basic Usage

```lua
-- Simple activation
vim.cmd.colorscheme('mapledark')
```

### Advanced Configuration

```lua
-- Load with options
require('mapledark').setup({
  -- Disable plugin highlights for faster load times
  disable_plugin_highlights = false,

  -- Load only specific plugin highlights (improves performance)
  plugins = { 'lazy', 'mason', 'telescope' },

  -- Force reload (clears cache)
  force = false,
})
```

### On-Demand Plugin Loading

```lua
-- Load specific plugin highlights only when needed
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'lazy',
  callback = function()
    require('mapledark').load_plugin('lazy')
  end,
})
```

### Theme Development

```lua
-- Clear cache and reload theme
require('mapledark').reload()

-- Clear cache only
require('mapledark').clear_cache()
```

### Vimscript

```vim
colorscheme mapledark
```

## ⚡ Performance

Maple Dark is optimized for performance with several caching mechanisms:

- **Color Caching**: Color palette is computed once and cached
- **Highlight Caching**: Theme won't reload if already loaded (unless forced)
- **Plugin Lazy Loading**: Plugin highlights are loaded asynchronously
- **Modular Plugin Support**: Load only the plugin highlights you need
- **Read-only Colors**: Color table is protected to prevent accidental modifications

These optimizations ensure fast startup times even with extensive plugin support.

## 📸 Screenshots

<!-- Add your screenshots here -->

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](#license) file for details.

## 🙏 Acknowledgments

- Inspired by the [VS Code Maple Theme](https://github.com/subframe7536/vscode-theme-maple)
- Built for the Neovim community

## 🔗 Links

- [GitHub Repository](https://github.com/abhilash26/mapledark.nvim)
- [Issue Tracker](https://github.com/abhilash26/mapledark.nvim/issues)

---

Made with 🍁 by abhilash26

