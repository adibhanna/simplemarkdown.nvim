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
    vim.api.nvim_win_set_option(0, 'conceallevel', M.config.conceal_level or 2)
    vim.api.nvim_win_set_option(0, 'concealcursor', M.config.show_raw_on_cursor and 'n' or 'nvc')

    -- Clear any existing syntax and set up fresh concealing
    vim.cmd('syntax clear')
    vim.cmd('syntax sync fromstart')

    -- Set up syntax concealing for markdown elements
    vim.cmd([[
    " Headers - conceal the # symbols and add spacing
    syntax match MarkdownH1 /^#\s/ conceal contained
    syntax match MarkdownH2 /^##\s/ conceal contained
    syntax match MarkdownH3 /^###\s/ conceal contained
    syntax match MarkdownH4 /^####\s/ conceal contained
    syntax match MarkdownH5 /^#####\s/ conceal contained
    syntax match MarkdownH6 /^######\s/ conceal contained

    " Header lines - include the concealed markers
    syntax match MarkdownHeaderLine /^#\s.*$/ contains=MarkdownH1
    syntax match MarkdownHeaderLine /^##\s.*$/ contains=MarkdownH2
    syntax match MarkdownHeaderLine /^###\s.*$/ contains=MarkdownH3
    syntax match MarkdownHeaderLine /^####\s.*$/ contains=MarkdownH4
    syntax match MarkdownHeaderLine /^#####\s.*$/ contains=MarkdownH5
    syntax match MarkdownHeaderLine /^######\s.*$/ contains=MarkdownH6

    " Bold text - conceal the ** markers
    syntax region MarkdownBold start=/\*\*/ end=/\*\*/ concealends oneline
    syntax region MarkdownBold start=/__/ end=/__/ concealends oneline

    " Italic text - conceal the * markers
    syntax region MarkdownItalic start=/\*/ end=/\*/ concealends oneline
    syntax region MarkdownItalic start=/_/ end=/_/ concealends oneline

    " Inline code - conceal the ` markers
    syntax region MarkdownInlineCode start=/`/ end=/`/ concealends oneline

    " Code blocks - conceal the ``` markers
    syntax match MarkdownCodeBlockStart /^```.*$/ conceal cchar=┌
    syntax match MarkdownCodeBlockEnd /^```$/ conceal cchar=└

    " List markers - replace with prettier symbols
    syntax match MarkdownListMarker /^\s*-\s/ conceal cchar=•
    syntax match MarkdownListMarker /^\s*\*\s/ conceal cchar=▪
    syntax match MarkdownListMarker /^\s*+\s/ conceal cchar=▫

    " Todo checkboxes - use monochrome symbols
    syntax match MarkdownTodoChecked /\[x\]/ conceal cchar=●
    syntax match MarkdownTodoChecked /\[X\]/ conceal cchar=●
    syntax match MarkdownTodoUnchecked /\[ \]/ conceal cchar=○
    syntax match MarkdownTodoUnchecked /\[\s\]/ conceal cchar=○

    " Links - conceal the URL part
    syntax region MarkdownLink start=/\[/ end=/\]/ concealends nextgroup=MarkdownLinkURL
    syntax region MarkdownLinkURL start=/(/ end=/)/ conceal contained
  ]])

    -- Apply highlighting to concealed elements
    vim.cmd([[
    highlight link MarkdownHeaderLine Title
    highlight link MarkdownBold Bold
    highlight link MarkdownItalic Italic
    highlight link MarkdownInlineCode String
    highlight link MarkdownCodeBlockStart Comment
    highlight link MarkdownCodeBlockEnd Comment
    highlight link MarkdownListMarker Operator
    highlight link MarkdownTodoChecked DiffAdd
    highlight link MarkdownTodoUnchecked DiffDelete
    highlight link MarkdownLink Underlined
  ]])

    -- Add spacing after headers using virtual text
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local ns_id = vim.api.nvim_create_namespace("SimpleMarkdownHeaderSpacing")

    -- Clear existing virtual text
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

    for i, line in ipairs(lines) do
        -- Check if line is a header
        if line:match("^#+%s") then
            -- Add virtual text for spacing after headers
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, i - 1, 0, {
                virt_lines = { { { "" } } }, -- Add empty line after header
                virt_lines_above = false,
            })
        end
    end
end

-- Remove preview mode concealing
function M.remove_preview_concealing(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    -- Reset concealing options (these are window options, not buffer options)
    vim.api.nvim_win_set_option(0, 'conceallevel', 0)
    vim.api.nvim_win_set_option(0, 'concealcursor', '')

    -- Clear syntax concealing
    vim.cmd([[
    syntax clear MarkdownH1
    syntax clear MarkdownH2
    syntax clear MarkdownH3
    syntax clear MarkdownH4
    syntax clear MarkdownH5
    syntax clear MarkdownH6
    syntax clear MarkdownHeaderLine
    syntax clear MarkdownBold
    syntax clear MarkdownItalic
    syntax clear MarkdownCodeBlockStart
    syntax clear MarkdownCodeBlockEnd
    syntax clear MarkdownInlineCode
    syntax clear MarkdownLink
    syntax clear MarkdownLinkURL
    syntax clear MarkdownListMarker
    syntax clear MarkdownTodoChecked
    syntax clear MarkdownTodoUnchecked
  ]])

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
