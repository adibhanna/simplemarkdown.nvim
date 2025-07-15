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

  -- Horizontal lines/rules
  safe_highlight("SimpleMarkdownHorizontalLine", {
    fg = colors.subtle
  })
end

-- Create full-width horizontal lines using virtual text
function M.apply_horizontal_lines()
  if not (M.config and M.config.horizontal_lines and M.config.horizontal_lines.enable) then
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local ns_id = vim.api.nvim_create_namespace("SimpleMarkdownHorizontalLines")

  -- Clear existing virtual text
  vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)

  -- Get window width for full-width line
  local win_width = vim.api.nvim_win_get_width(0)
  local line_char = string.rep("─", math.max(win_width - 2, 3))

  for i, line in ipairs(lines) do
    -- Check if line matches horizontal line patterns
    if line:match("^%s*%-%-%-+%s*$") or
        line:match("^%s*%*%*%*+%s*$") or
        line:match("^%s*___+%s*$") then
      -- Add virtual text to replace the line
      vim.api.nvim_buf_set_extmark(buf, ns_id, i - 1, 0, {
        virt_text = { { line_char, "SimpleMarkdownHorizontalLine" } },
        virt_text_pos = "overlay",
        hl_mode = "combine"
      })
    end
  end
end

-- Apply syntax highlighting using buffer-based approach
function M.apply_highlights()
  local buf = vim.api.nvim_get_current_buf()

  -- Check if we're in preview mode
  local preview_mode = false
  if M.config and M.config.preview_mode and M.config.preview_mode.enable then
    local preview = require("simplemarkdown.preview")
    preview_mode = preview.get_mode(buf) == "preview"
  end

  -- Don't apply matchadd highlights in preview mode (syntax concealing handles it)
  if preview_mode then
    -- Apply horizontal lines only in preview mode
    M.apply_horizontal_lines()
    return
  end

  -- Clear existing matches only if not in preview mode
  pcall(vim.fn.clearmatches)

  -- Use a more robust approach with protected calls
  local function safe_matchadd(group, pattern)
    local success, result = pcall(vim.fn.matchadd, group, pattern)
    if not success then
      -- Fallback: try with simpler syntax
      pcall(vim.fn.matchadd, group, pattern, 10)
    end
  end

  -- Only apply minimal highlighting in edit mode

  -- Headers (only the # symbols)
  safe_matchadd("SimpleMarkdownH1", "^#\\s")
  safe_matchadd("SimpleMarkdownH2", "^##\\s")
  safe_matchadd("SimpleMarkdownH3", "^###\\s")
  safe_matchadd("SimpleMarkdownH4", "^####\\s")
  safe_matchadd("SimpleMarkdownH5", "^#####\\s")
  safe_matchadd("SimpleMarkdownH6", "^######\\s")

  -- Code blocks (fenced) - simplified
  safe_matchadd("SimpleMarkdownCodeBlockBorder", "^```")
  safe_matchadd("SimpleMarkdownCodeBlockBorder", "^~~~")

  -- Basic horizontal lines in edit mode (show raw text)
  safe_matchadd("SimpleMarkdownHorizontalLine", "^---\\+$")
  safe_matchadd("SimpleMarkdownHorizontalLine", "^\\*\\*\\*\\+$")
  safe_matchadd("SimpleMarkdownHorizontalLine", "^___\\+$")
end

-- Alternative approach using autocmds for more robust highlighting
function M.setup_autocmds()
  local group = vim.api.nvim_create_augroup("SimpleMarkdownHighlights", { clear = true })

  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "TextChanged", "TextChangedI" }, {
    group = group,
    pattern = { "*.md" },
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

  -- Refresh horizontal lines when window is resized
  vim.api.nvim_create_autocmd("VimResized", {
    group = group,
    callback = function()
      -- Reapply horizontal lines for markdown files
      if vim.bo.filetype == "markdown" then
        apply_horizontal_lines()
      end
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
