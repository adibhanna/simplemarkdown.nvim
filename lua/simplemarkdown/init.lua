local M = {}

-- Default configuration
M.config = {
    -- Todo highlighting options
    todo = {
        enable = true,
        highlight_dates = true,
        date_format = "%Y-%m-%d", -- strftime format
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
}

-- Setup function to initialize the plugin
function M.setup(user_config)
    -- Merge user config with defaults
    if user_config then
        M.config = vim.tbl_deep_extend("force", M.config, user_config)
    end

    -- Only proceed if plugin is enabled
    if not M.config.enabled then
        return
    end

    -- Load highlight groups
    require("simplemarkdown.highlights").setup(M.config)

    -- Set up autocmds for markdown files
    local group = vim.api.nvim_create_augroup("SimpleMarkdown", { clear = true })

    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "markdown",
        callback = function()
            require("simplemarkdown.highlights").apply_highlights()
        end,
    })

    -- Apply highlights to already open markdown buffers
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
            local ft = vim.api.nvim_buf_get_option(buf, "filetype")
            if ft == "markdown" then
                require("simplemarkdown.highlights").apply_highlights()
            end
        end
    end
end

return M
