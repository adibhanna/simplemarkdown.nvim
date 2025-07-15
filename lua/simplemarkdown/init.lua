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

-- Debug function to check if .mdc files are working
function M.debug_mdc()
    local buf = vim.api.nvim_get_current_buf()
    local filename = vim.api.nvim_buf_get_name(buf)
    local filetype = vim.bo[buf].filetype

    print("Filename: " .. filename)
    print("Filetype: " .. filetype)
    print("Is markdown: " .. (filetype == "markdown" and "Yes" or "No"))

    if filename:match("%.mdc$") then
        print("This is a .mdc file")
        if filetype == "markdown" then
            print("✓ Filetype detection is working")
        else
            print("✗ Filetype detection is NOT working")
        end
    end
end

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

    -- Enhanced filetype detection for .mdc files
    vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile", "BufEnter" }, {
        group = group,
        pattern = "*.mdc",
        callback = function()
            vim.bo.filetype = "markdown"
            -- Also ensure it gets the markdown syntax
            vim.cmd("set syntax=markdown")
            -- Force apply highlights immediately
            vim.defer_fn(function()
                if vim.bo.filetype == "markdown" then
                    require("simplemarkdown.highlights").apply_highlights()
                end
            end, 100)
        end,
    })

    -- Alternative approach: use vim.filetype.add for more robust detection
    vim.filetype.add({
        extension = {
            mdc = "markdown",
        },
    })

    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "markdown",
        callback = function()
            require("simplemarkdown.highlights").apply_highlights()
        end,
    })

    -- Apply highlights to already open markdown buffers (including .mdc)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
            local ft = vim.api.nvim_buf_get_option(buf, "filetype")
            local filename = vim.api.nvim_buf_get_name(buf)
            if ft == "markdown" or filename:match("%.mdc$") then
                -- Ensure .mdc files have correct filetype
                if filename:match("%.mdc$") then
                    vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
                end

                -- Apply preview mode if enabled
                if M.config.preview_mode and M.config.preview_mode.enable then
                    local preview = require("simplemarkdown.preview")
                    preview.setup_buffer(buf, M.config.preview_mode)
                end

                require("simplemarkdown.highlights").apply_highlights()
            end
        end
    end

    -- Add user commands for debugging and manual control
    vim.api.nvim_create_user_command('SimpleMarkdownDebug', function()
        M.debug_mdc()
    end, {})

    vim.api.nvim_create_user_command('SimpleMarkdownForceHighlight', function()
        require("simplemarkdown.highlights").apply_highlights()
    end, {})

    vim.api.nvim_create_user_command('SimpleMarkdownForceMDC', function()
        vim.bo.filetype = "markdown"
        vim.cmd("set syntax=markdown")
        require("simplemarkdown.highlights").apply_highlights()
    end, {})

    vim.api.nvim_create_user_command('SimpleMarkdownTestPreview', function()
        local preview = require("simplemarkdown.preview")
        local mode = preview.get_mode()
        print("SimpleMarkdown current mode: " .. mode)
        if mode == "edit" then
            preview.set_mode(vim.api.nvim_get_current_buf(), "preview")
            preview.apply_preview_concealing()
            print("✓ Switched to preview mode")
        else
            print("✓ Already in preview mode")
        end
    end, {})
end

return M
