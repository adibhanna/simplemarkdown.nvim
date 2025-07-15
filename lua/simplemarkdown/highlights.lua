local M = {}

-- Get current theme colors
local function get_theme_colors()
  local colors = {}

  -- Get common highlight groups from current theme
  local function get_hl_color(group, attr)
    local hl = vim.api.nvim_get_hl(0, { name = group })
    return hl[attr] and string.format("#%06x", hl[attr]) or nil
  end

  -- Use very subtle highlight groups from the theme
  colors.subtle = get_hl_color("Comment", "fg")
  colors.muted = get_hl_color("NonText", "fg") or get_hl_color("LineNr", "fg")
  colors.normal = get_hl_color("Normal", "fg")
  colors.string = get_hl_color("String", "fg")
  colors.number = get_hl_color("Number", "fg")
  colors.keyword = get_hl_color("Keyword", "fg")
  colors.type = get_hl_color("Type", "fg")
  colors.identifier = get_hl_color("Identifier", "fg")
  colors.function_name = get_hl_color("Function", "fg")

  return colors
end

-- Define highlight groups using theme colors
local function define_highlight_groups()
  local colors = get_theme_colors()

  -- Helper function to safely set highlight with nil check
  local function safe_highlight(name, opts)
    -- Only set if we have a valid color
    if opts.fg then
      vim.api.nvim_set_hl(0, name, vim.tbl_extend("force", opts, { default = true }))
    end
  end

  -- Todo list highlights (softer approach)
  safe_highlight("SimpleMarkdownTodo", {
    fg = colors.muted or colors.subtle
  })

  safe_highlight("SimpleMarkdownTodoUnchecked", {
    fg = colors.muted or colors.subtle
  })

  safe_highlight("SimpleMarkdownTodoChecked", {
    fg = colors.subtle,
    italic = true
  })

  safe_highlight("SimpleMarkdownTodoDate", {
    fg = colors.muted or colors.subtle,
    italic = true
  })

  -- Code block highlights (subtle)
  safe_highlight("SimpleMarkdownCodeBlock", {
    fg = colors.normal
  })

  safe_highlight("SimpleMarkdownCodeBlockBorder", {
    fg = colors.muted or colors.subtle
  })

  safe_highlight("SimpleMarkdownCodeInline", {
    fg = colors.muted or colors.subtle
  })

  -- Header highlights (very subtle, only H1 gets slight emphasis)
  safe_highlight("SimpleMarkdownH1", {
    fg = colors.normal,
    bold = true
  })

  safe_highlight("SimpleMarkdownH2", {
    fg = colors.normal
  })

  safe_highlight("SimpleMarkdownH3", {
    fg = colors.normal
  })

  safe_highlight("SimpleMarkdownH4", {
    fg = colors.normal
  })

  safe_highlight("SimpleMarkdownH5", {
    fg = colors.normal
  })

  safe_highlight("SimpleMarkdownH6", {
    fg = colors.normal
  })

  -- List highlights (very subtle)
  safe_highlight("SimpleMarkdownListMarker", {
    fg = colors.muted or colors.subtle
  })

  safe_highlight("SimpleMarkdownEmphasis", {
    fg = colors.normal,
    italic = true
  })

  safe_highlight("SimpleMarkdownStrong", {
    fg = colors.normal,
    bold = true
  })

  safe_highlight("SimpleMarkdownLink", {
    fg = colors.identifier or colors.normal,
    underline = true
  })

  safe_highlight("SimpleMarkdownLinkText", {
    fg = colors.normal
  })
end

-- Apply syntax highlighting using buffer-based approach
function M.apply_highlights()
  local buf = vim.api.nvim_get_current_buf()

  -- Clear existing matches
  pcall(vim.fn.clearmatches)

  -- Use a more robust approach with protected calls
  local function safe_matchadd(group, pattern)
    local success, result = pcall(vim.fn.matchadd, group, pattern)
    if not success then
      -- Fallback: try with simpler syntax
      pcall(vim.fn.matchadd, group, pattern, 10)
    end
  end

  -- Todo lists with checkboxes (simplified patterns)
  safe_matchadd("SimpleMarkdownTodoUnchecked", "^\\s*[-*+]\\s*\\[\\s\\]")
  safe_matchadd("SimpleMarkdownTodoChecked", "^\\s*[-*+]\\s*\\[x\\]")
  safe_matchadd("SimpleMarkdownTodoChecked", "^\\s*[-*+]\\s*\\[X\\]")

  -- Dates (simplified patterns)
  safe_matchadd("SimpleMarkdownTodoDate", "\\d\\{4\\}-\\d\\{2\\}-\\d\\{2\\}")
  safe_matchadd("SimpleMarkdownTodoDate", "@\\d\\{4\\}-\\d\\{2\\}-\\d\\{2\\}")

  -- Code blocks (fenced) - simplified
  safe_matchadd("SimpleMarkdownCodeBlockBorder", "^```")
  safe_matchadd("SimpleMarkdownCodeBlockBorder", "^~~~")

  -- Headers
  safe_matchadd("SimpleMarkdownH1", "^#\\s")
  safe_matchadd("SimpleMarkdownH2", "^##\\s")
  safe_matchadd("SimpleMarkdownH3", "^###\\s")
  safe_matchadd("SimpleMarkdownH4", "^####\\s")
  safe_matchadd("SimpleMarkdownH5", "^#####\\s")
  safe_matchadd("SimpleMarkdownH6", "^######\\s")

  -- List markers
  safe_matchadd("SimpleMarkdownListMarker", "^\\s*[-*+]\\s")
  safe_matchadd("SimpleMarkdownListMarker", "^\\s*\\d\\+\\.")

  -- Emphasis and strong (simplified)
  safe_matchadd("SimpleMarkdownStrong", "\\*\\*[^*]*\\*\\*")
  safe_matchadd("SimpleMarkdownStrong", "__[^_]*__")
  safe_matchadd("SimpleMarkdownEmphasis", "\\*[^*]*\\*")
  safe_matchadd("SimpleMarkdownEmphasis", "_[^_]*_")

  -- Links (simplified patterns)
  safe_matchadd("SimpleMarkdownLinkText", "\\[[^\\]]*\\]")
end

-- Alternative approach using autocmds for more robust highlighting
function M.setup_autocmds()
  local group = vim.api.nvim_create_augroup("SimpleMarkdownHighlights", { clear = true })

  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "TextChanged", "TextChangedI" }, {
    group = group,
    pattern = "*.md",
    callback = function()
      -- Small delay to allow buffer to stabilize
      vim.defer_fn(function()
        if vim.bo.filetype == "markdown" then
          M.apply_highlights()
        end
      end, 50)
    end,
  })

  -- Refresh highlights when colorscheme changes
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      -- Redefine highlight groups with new theme colors
      define_highlight_groups()
      -- Reapply highlights to any open markdown files
      vim.defer_fn(function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buf) then
            local ft = vim.bo[buf].filetype
            if ft == "markdown" then
              M.apply_highlights()
            end
          end
        end
      end, 100)
    end,
  })
end

-- Setup function
function M.setup(config)
  M.config = config or {}

  -- Define highlight groups
  define_highlight_groups()

  -- Setup autocmds for additional robustness
  M.setup_autocmds()
end

return M
