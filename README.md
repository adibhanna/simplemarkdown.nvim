# SimpleMarkdown.nvim

A simple, beautiful markdown highlighting plugin for Neovim that integrates seamlessly with your colorscheme.

## Quick Start

Add to your Neovim config:

```lua
require("simplemarkdown").setup({
  preview_mode = {
    enable = true,
    default_mode = "preview",
  },
})
```

Then test with:
- `:SimpleMarkdownTestPreview` - Check current mode
- `:SimpleMarkdownToggle` - Toggle between preview/edit modes

## Features

- 🎨 **Theme Integration**: Uses colors from your current colorscheme
- 📝 **Todo Lists**: Highlights checkboxes, dates, and task items
- 📋 **Headers**: Subtle highlighting for all header levels
- 🔗 **Links**: Clean link highlighting
- 💻 **Code Blocks**: Syntax highlighting for fenced code blocks
- 📏 **Horizontal Lines**: Full-width visual lines for `---`, `***`, `___`
- 🔄 **Preview Mode**: Toggle between rendered preview and edit modes
- 📄 **Multi-format**: Supports both `.md` and `.mdc` files

## Preview Mode

The plugin includes a powerful preview/edit mode toggle system:

### Preview Mode (Default)
- **Headers**: Shows clean text without `#` symbols
- **Bold/Italic**: Displays formatted text without `**` or `*` markers
- **Code**: Shows inline code without `` ` `` backticks
- **Lists**: Beautiful bullets (• ▪ ▫) instead of `- * +`
- **Checkboxes**: ✓ and □ instead of `[x]` and `[ ]`
- **Links**: Shows only link text, hides URLs
- **Code Blocks**: Clean borders instead of `` ``` ``

### Edit Mode
- Shows all raw markdown syntax for editing
- Full access to all markdown markup
- Perfect for making changes

### Toggle Controls
- **Commands**: 
  - `:SimpleMarkdownToggle` - Toggle between modes
  - `:SimpleMarkdownPreview` - Switch to preview mode
  - `:SimpleMarkdownEdit` - Switch to edit mode

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "adibhanna/simplemarkdown.nvim",
  ft = { "markdown" },
  config = function()
    require("simplemarkdown").setup({
      -- Preview mode settings
      preview_mode = {
        enable = true,
        default_mode = "preview", -- "preview" or "edit"
        conceal_level = 2,
        show_raw_on_cursor = true, -- Show raw markdown when cursor is on line
      },
      -- Other settings...
    })
  end,
}
```

## Configuration

```lua
require("simplemarkdown").setup({
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

  -- Horizontal lines/rules
  horizontal_lines = {
    enable = true,
    style = "line",
  },

  -- Preview mode settings
  preview_mode = {
    enable = true,
    default_mode = "preview", -- "preview" or "edit"
    conceal_level = 2,
    show_raw_on_cursor = true,
  },

  -- Enable/disable the plugin
  enabled = true,
})
```

## Usage

### Basic Usage
1. Open any `.md` or `.mdc` file
2. The plugin automatically applies highlighting
3. By default, files open in **preview mode**
4. Use `:SimpleMarkdownToggle` to switch to **edit mode**
5. Use `:SimpleMarkdownToggle` again to return to **preview mode**

### Status Check
Get the current mode status:
```lua
local mode = require("simplemarkdown").get_mode_status()
print("Current mode: " .. mode) -- "preview" or "edit"
```

### Manual Toggle
```lua
require("simplemarkdown").toggle_preview()
```

## Debugging

If you're having issues with `.mdc` files:

1. Check filetype detection: `:SimpleMarkdownDebug`
2. Force markdown treatment: `:SimpleMarkdownForceMDC`
3. Manual highlighting: `:SimpleMarkdownForceHighlight`

## License

MIT License
