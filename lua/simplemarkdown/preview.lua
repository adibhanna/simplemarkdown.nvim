local M = {}

-- Current mode state per buffer
local buffer_modes = {}

-- Get current mode for buffer
function M.get_mode(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    return buffer_modes[bufnr] or "preview"
end

-- Set mode for buffer
function M.set_mode(bufnr, mode)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    buffer_modes[bufnr] = mode
end

-- Apply preview mode concealing
function M.apply_preview_concealing(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    -- Set concealing options (these are window options, not buffer options)
    vim.api.nvim_win_set_option(0, 'conceallevel', 2)
    vim.api.nvim_win_set_option(0, 'concealcursor', 'n')

    -- Clear any existing syntax and set up fresh concealing
    vim.cmd('syntax clear')
    vim.cmd('syntax sync fromstart')

    -- Ensure markdown filetype is set
    vim.bo[bufnr].filetype = "markdown"

    -- Set up syntax concealing for markdown elements
    vim.cmd([[

        " Todo checkboxes and strikethrough - completely disabled, handled by virtual text only

    " Headers - conceal the # symbols (simple approach)
    syntax match MarkdownH1 /^#\s/ conceal
    syntax match MarkdownH2 /^##\s/ conceal
    syntax match MarkdownH3 /^###\s/ conceal
    syntax match MarkdownH4 /^####\s/ conceal
    syntax match MarkdownH5 /^#####\s/ conceal
    syntax match MarkdownH6 /^######\s/ conceal

    " Bold text - conceal the ** markers
    syntax region MarkdownBold start=/\*\*/ end=/\*\*/ concealends oneline
    syntax region MarkdownBold start=/__/ end=/__/ concealends oneline

    " Italic text - disabled to avoid weird characters
    " syntax region MarkdownItalic start=/\*/ end=/\*/ concealends oneline
    " syntax region MarkdownItalic start=/_/ end=/_/ concealends oneline

    " Inline code - conceal the ` markers
    syntax region MarkdownInlineCode start=/`/ end=/`/ concealends oneline

    " List markers - now handled by virtual text for proper spacing
    " syntax match MarkdownListMarker /^\s*-\s/ conceal
    " syntax match MarkdownListMarker /^\s*\*\s/ conceal
    " syntax match MarkdownListMarker /^\s*+\s/ conceal

    " Links - conceal the URL part and underline the text
    syntax region MarkdownLink start=/\[/ end=/\]/ concealends nextgroup=MarkdownLinkURL
    syntax region MarkdownLinkURL start=/(/ end=/)/ conceal contained
  ]])

    -- Apply highlighting to concealed elements
    vim.cmd([[
    highlight link MarkdownH1 Title
    highlight link MarkdownH2 Title
    highlight link MarkdownH3 Title
    highlight link MarkdownH4 Title
    highlight link MarkdownH5 Title
    highlight link MarkdownH6 Title
    highlight link MarkdownBold Bold
    highlight link MarkdownInlineCode String
    highlight link MarkdownListMarker Operator
    highlight link MarkdownTodoChecked DiffAdd
    highlight link MarkdownTodoUnchecked DiffDelete

    " Links - ensure they are underlined
    highlight link MarkdownLink SimpleMarkdownLink

    " Clean check mark without background
    highlight MarkdownTodoCheckedClean guifg=green ctermfg=green

    " Completed tasks with strikethrough
    highlight MarkdownCompletedTask gui=strikethrough cterm=strikethrough
  ]])

    -- Force redraw to ensure concealing takes effect
    vim.cmd('redraw!')

    -- Double-check concealing is active
    if vim.api.nvim_win_get_option(0, 'conceallevel') < 2 then
        vim.api.nvim_win_set_option(0, 'conceallevel', 2)
    end

    -- Add spacing after headers and fix list markers using virtual text
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local ns_id_header = vim.api.nvim_create_namespace("SimpleMarkdownHeaderSpacing")
    local ns_id_list = vim.api.nvim_create_namespace("SimpleMarkdownListMarkers")
    local ns_id_checkbox = vim.api.nvim_create_namespace("SimpleMarkdownCheckboxes")

    -- Clear existing virtual text
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id_header, 0, -1)
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id_list, 0, -1)
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id_checkbox, 0, -1)

    for i, line in ipairs(lines) do
        -- Check if line is a header
        if line:match("^#+%s") then
            -- Add virtual text for spacing after headers
            vim.api.nvim_buf_set_extmark(bufnr, ns_id_header, i - 1, 0, {
                virt_lines = { { { "" } } }, -- Add one empty line after header
                virt_lines_above = false,
            })
        end

        -- Handle checkboxes with virtual text - match checkbox with space directly
        -- Look for [x], [X], or [ ] patterns followed by a space
        local checkbox_start, checkbox_end = line:find("%[[ xX]%]%s")
        if checkbox_start then
            local checkbox_text = line:sub(checkbox_start, checkbox_start + 2) -- Just the [x] part

            if checkbox_text:match("%[x%]") or checkbox_text:match("%[X%]") then
                -- Completed task: show check icon
                vim.api.nvim_buf_set_extmark(bufnr, ns_id_checkbox, i - 1, checkbox_start - 1, {
                    end_col = checkbox_end, -- Cover entire checkbox + space (end_col is exclusive)
                    virt_text = { { "✓ ", "MarkdownTodoCheckedClean" } },
                    virt_text_pos = "overlay",
                    hl_mode = "combine"
                })
            else
                -- Uncompleted task: hide the checkbox completely
                vim.api.nvim_buf_set_extmark(bufnr, ns_id_checkbox, i - 1, checkbox_start - 1, {
                    end_col = checkbox_end, -- Cover entire checkbox + space (end_col is exclusive)
                    virt_text = { { "  ", "MarkdownTodoUnchecked" } },
                    virt_text_pos = "overlay",
                    hl_mode = "combine"
                })
            end
        end

        -- Handle list markers with proper spacing (skip if it's a todo item)
        local list_start, list_end = line:find("^%s*[-*+]%s")
        if list_start and not line:match("%[[ xX]%]") then
            local marker_text = line:sub(list_start, list_end)
            local replacement_char = "• " -- Default bullet with space

            if marker_text:match("%-") then
                replacement_char = "• "
            elseif marker_text:match("%*") then
                replacement_char = "▪ "
            elseif marker_text:match("%+") then
                replacement_char = "▫ "
            end

            -- Replace the list marker with virtual text
            vim.api.nvim_buf_set_extmark(bufnr, ns_id_list, i - 1, list_start - 1, {
                end_col = list_end,
                virt_text = { { replacement_char, "MarkdownListMarker" } },
                virt_text_pos = "overlay",
                hl_mode = "combine"
            })
        end
    end

    -- Apply horizontal lines in preview mode
    require("simplemarkdown.highlights").apply_horizontal_lines()
end

-- Remove preview mode concealing
function M.remove_preview_concealing(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    -- Reset concealing options (these are window options, not buffer options)
    vim.api.nvim_win_set_option(0, 'conceallevel', 0)
    vim.api.nvim_win_set_option(0, 'concealcursor', '')

    -- Clear syntax concealing
    vim.cmd('syntax clear')

    -- Clear virtual text spacing, horizontal lines, list markers, and checkboxes
    local ns_id_header = vim.api.nvim_create_namespace("SimpleMarkdownHeaderSpacing")
    local ns_id_horizontal = vim.api.nvim_create_namespace("SimpleMarkdownHorizontalLines")
    local ns_id_list = vim.api.nvim_create_namespace("SimpleMarkdownListMarkers")
    local ns_id_checkbox = vim.api.nvim_create_namespace("SimpleMarkdownCheckboxes")
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id_header, 0, -1)
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id_horizontal, 0, -1)
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id_list, 0, -1)
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id_checkbox, 0, -1)

    -- Reset syntax to default markdown
    vim.cmd('set syntax=markdown')
end

-- Toggle between preview and edit modes
function M.toggle_mode(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local current_mode = M.get_mode(bufnr)

    if current_mode == "preview" then
        -- Switch to edit mode
        M.set_mode(bufnr, "edit")
        M.remove_preview_concealing(bufnr)
        print("Switched to edit mode")
    else
        -- Switch to preview mode
        M.set_mode(bufnr, "preview")
        M.apply_preview_concealing(bufnr)
        print("Switched to preview mode")
    end

    -- Reapply syntax highlighting
    require("simplemarkdown.highlights").apply_highlights()
end

-- Set up preview mode for a buffer
function M.setup_buffer(bufnr, config)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    M.config = config or {}

    -- Set initial mode based on config
    local initial_mode = M.config.default_mode or "preview"
    M.set_mode(bufnr, initial_mode)

    -- Apply initial mode
    if initial_mode == "preview" then
        M.apply_preview_concealing(bufnr)
    end
end

-- Initialize preview mode
function M.setup(config)
    M.config = config or {}

    -- Set up autocmd to initialize preview mode for markdown files
    local group = vim.api.nvim_create_augroup("SimpleMarkdownPreview", { clear = true })

    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "markdown",
        callback = function()
            if M.config.enable then
                M.setup_buffer(vim.api.nvim_get_current_buf(), M.config)
            end
        end,
    })



    -- Add user commands
    vim.api.nvim_create_user_command('SimpleMarkdownToggle', function()
        M.toggle_mode()
    end, { desc = "Toggle markdown preview/edit mode" })

    vim.api.nvim_create_user_command('SimpleMarkdownPreview', function()
        M.set_mode(vim.api.nvim_get_current_buf(), "preview")
        M.apply_preview_concealing()
        require("simplemarkdown.highlights").apply_highlights()
    end, { desc = "Switch to markdown preview mode" })

    vim.api.nvim_create_user_command('SimpleMarkdownEdit', function()
        M.set_mode(vim.api.nvim_get_current_buf(), "edit")
        M.remove_preview_concealing()
        require("simplemarkdown.highlights").apply_highlights()
    end, { desc = "Switch to markdown edit mode" })
end

return M
