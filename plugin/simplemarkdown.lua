-- simplemarkdown.nvim - Enhanced Markdown Highlighting Plugin
-- Auto-initialization for the plugin

-- Prevent loading if already loaded
if vim.g.loaded_simplemarkdown then
    return
end
vim.g.loaded_simplemarkdown = true

-- Only load for supported neovim versions
if vim.fn.has("nvim-0.7") == 0 then
    vim.api.nvim_err_writeln("simplemarkdown.nvim requires Neovim 0.7+")
    return
end

-- Setup the plugin with default configuration
require("simplemarkdown").setup()
