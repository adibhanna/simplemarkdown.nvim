# simplemarkdown.nvim

A beautiful Neovim plugin that adds enhanced visual highlights to markdown files, making your notes easier to read and more visually appealing.

## ✨ Features

- **Enhanced Todo Lists**: Beautiful highlighting for todo items with checkboxes
- **Date Highlighting**: Automatic detection and highlighting of dates in various formats
- **Code Block Enhancement**: Improved visual separation for code blocks
- **Header Styling**: Gradient-style headers with background colors
- **Link Beautification**: Elegant highlighting for markdown links
- **List Improvements**: Better visual markers for ordered and unordered lists
- **Emphasis Styling**: Enhanced italic and bold text highlighting

## 📦 Installation

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'adibhanna/simplemarkdown.nvim',
  config = function()
    require('simplemarkdown').setup()
  end
}
```

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'adibhanna/simplemarkdown.nvim',
  ft = 'markdown',
  config = function()
    require('simplemarkdown').setup()
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'adibhanna/simplemarkdown.nvim'
```

Then add to your `init.lua`:

```lua
require('simplemarkdown').setup()
```

## 🚀 Usage

The plugin works automatically once installed. Simply open any markdown file and enjoy the enhanced highlighting!

### Todo Lists

The plugin automatically highlights todo items:

```markdown
- [ ] Unchecked todo item @2024-01-15
- [x] Completed todo item 2024-01-15
- [X] Another completed item
```

### Dates

Supports multiple date formats:
- ISO format: `2024-01-15`
- US format: `01/15/2024`
- European format: `15-01-2024`
- Tagged dates: `@2024-01-15`

### Code Blocks

Enhanced highlighting for fenced code blocks:

````markdown
```lua
local config = {
  enable = true
}
```
````

## ⚙️ Configuration

You can customize the plugin by passing options to the setup function:

```lua
require('simplemarkdown').setup({
  -- Todo highlighting options
  todo = {
    enable = true,
    highlight_dates = true,
    date_format = "%Y-%m-%d",
  },
  
  -- Code block highlighting options
  code = {
    enable = true,
    background = true,
    border = true,
  },
  
  -- Header highlighting options
  headers = {
    enable = true,
    background = true,
  },
  
  -- List highlighting options
  lists = {
    enable = true,
    indent_guides = true,
  },
  
  -- Enable/disable the plugin
  enabled = true,
})
```

## 🎨 Dynamic Color Scheme

The plugin **automatically adapts to your current colorscheme**! It intelligently extracts colors from your theme's highlight groups:

- **Todo Unchecked**: Uses your theme's error color (DiagnosticError/ErrorMsg)
- **Todo Checked**: Uses your theme's success color (DiagnosticOk/DiffAdd) + strikethrough
- **Dates**: Uses your theme's constant/statement color
- **Code Blocks**: Uses your theme's comment color for borders
- **Headers**: Uses a gradient of your theme's diagnostic colors (H1-H6)
- **Links**: Uses your theme's info/function color
- **Emphasis**: Uses your theme's special/hint color

The plugin automatically updates when you change colorschemes!

## 🔧 Customization

### Custom Highlight Groups

The plugin automatically adapts to your colorscheme, but you can still override specific highlights:

```lua
vim.api.nvim_set_hl(0, "SimpleMarkdownTodoUnchecked", { fg = "#your_color" })
vim.api.nvim_set_hl(0, "SimpleMarkdownTodoChecked", { fg = "#your_color", strikethrough = true })
vim.api.nvim_set_hl(0, "SimpleMarkdownTodoDate", { fg = "#your_color", italic = true })
```

The plugin will respect your custom highlights and won't override them.

### Disable Specific Features

```lua
require('simplemarkdown').setup({
  todo = { enable = false },     -- Disable todo highlighting
  code = { enable = false },     -- Disable code block enhancements
  headers = { enable = false },  -- Disable header styling
})
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- Inspired by the need for better markdown reading experience in Neovim
- Color palette inspired by the Tokyo Night theme
- Thanks to the Neovim community for their excellent plugin ecosystem 