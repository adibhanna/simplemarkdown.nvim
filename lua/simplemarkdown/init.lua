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

    -- Horizontal lines/rules
    horizontal_lines = {
        enable = true,
        style = "line", -- "line" or "highlight"
    },

    -- Preview mode settings
    preview_mode = {
        enable = true,
        default_mode = "preview",  -- "preview" or "edit"
        conceal_level = 2,         -- Level of concealing in preview mode
        show_raw_on_cursor = true, -- Show raw markdown when cursor is on line
    },

    -- Enable/disable the plugin
    enabled = true,
}



-- Get current preview mode status
function M.get_mode_status()
    if M.config.preview_mode and M.config.preview_mode.enable then
        local preview = require("simplemarkdown.preview")
        return preview.get_mode()
    end
    return "edit" -- Default if preview mode is disabled
end

-- Toggle preview mode (shortcut function)
function M.toggle_preview()
    if M.config.preview_mode and M.config.preview_mode.enable then
        require("simplemarkdown.preview").toggle_mode()
    else
        print("Preview mode is not enabled")
    end
end

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

    -- Load preview mode if enabled
    if M.config.preview_mode and M.config.preview_mode.enable then
        require("simplemarkdown.preview").setup(M.config.preview_mode)
    end

    -- Set up autocmds for markdown files
    local group = vim.api.nvim_create_augroup("SimpleMarkdown", { clear = true })




    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "markdown",
        callback = function()
            local buf = vim.api.nvim_get_current_buf()

            -- Apply preview mode if enabled
            if M.config.preview_mode and M.config.preview_mode.enable then
                local preview = require("simplemarkdown.preview")
                preview.setup_buffer(buf, M.config.preview_mode)
            end

            require("simplemarkdown.highlights").apply_highlights()
        end,
    })

    -- Apply highlights to already open markdown buffers
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
            local ft = vim.api.nvim_buf_get_option(buf, "filetype")
            if ft == "markdown" then
                -- Apply preview mode if enabled
                if M.config.preview_mode and M.config.preview_mode.enable then
                    local preview = require("simplemarkdown.preview")
                    preview.setup_buffer(buf, M.config.preview_mode)
                end

                require("simplemarkdown.highlights").apply_highlights()
            end
        end
    end
end

return M
