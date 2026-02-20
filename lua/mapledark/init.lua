-- Maple Dark - A colorful dark theme with medium brightness and low saturation
-- Inspired by: https://github.com/subframe7536/vscode-theme-maple
-- License: MIT

local M = {}
local utils = require('mapledark.utils')
local hl = utils.hl

-- Cache for colors and highlights
local _cache = {
  colors = nil,
  highlights_loaded = false,
  plugins_loaded = {},
}

-- Get cached colors or create them
local function get_colors()
  if _cache.colors then
    return _cache.colors
  end

  _cache.colors = {
    -- Background colors
    bg_dark   = '#121315',  -- main terminal background
    bg        = '#797e85',  -- secondary bg (e.g., folds, floating)
    bg_light  = '#7c8794',  -- lighter panels
    bg_sel    = '#8f909d',  -- selection background
    border    = '#7c808d',  -- border lines / window edges

    -- Foreground colors
    fg        = '#cbd5e1',  -- main text
    fg_dark   = '#98a2b3',  -- comments / muted text
    fg_light  = '#ffffff',  -- bright highlights / prompts
    linenr    = '#b0b6c2',  -- line numbers

    -- Semantic / syntax colors
    red       = '#f0b3b3',  -- errors, warnings
    orange    = '#f1d0a3',  -- warnings, hints
    yellow    = '#fff0c0',  -- highlights / TODOs
    green     = '#a8e0b5',  -- success / diff add
    cyan      = '#a6ebe9',  -- info / types
    blue      = '#95d0ff',  -- functions / keywords
    magenta   = '#d7d0ff',  -- classes / strings / tags
    accent    = '#c2ffff',  -- cursor / accent

    -- Brighter variants (for floating windows, popups, or emphasis)
    red_br     = '#ffc9c9',
    orange_br  = '#ffe0a3',
    yellow_br  = '#fff8d0',
    green_br   = '#c1fcd3',
    cyan_br    = '#d0f8f6',
    blue_br    = '#b0e4ff',
    magenta_br = '#f0ebff',
  }

  return _cache.colors
end


-- Expose colors as a property
M.colors = setmetatable({}, {
  __index = function(_, key)
    return get_colors()[key]
  end,
  __newindex = function()
    error("Colors table is read-only", 2)
  end,
})

-- Apply the colorscheme
function M.setup(opts)
  opts = opts or {}

  -- Check if already loaded and not forcing reload
  if _cache.highlights_loaded and not opts.force then
    return
  end

  -- Reset colors
  vim.cmd('highlight clear')
  if vim.fn.exists('syntax_on') then
    vim.cmd('syntax reset')
  end

  vim.g.colors_name = 'mapledark'
  vim.o.background = 'dark'
  vim.o.termguicolors = true

  local c = get_colors()

  -- ============================================================================
  -- EDITOR UI
  -- ============================================================================

  hl('Normal', { fg = c.fg, bg = c.bg_dark })
  hl('NormalFloat', { fg = c.fg, bg = c.bg_dark })
  hl('FloatBorder', { fg = c.border, bg = c.bg_dark })
  hl('FloatTitle', { fg = c.blue, bg = c.bg_light, bold = true })

  hl('Cursor', { fg = c.bg, bg = c.fg })
  hl('lCursor', { fg = c.bg, bg = c.fg })
  hl('CursorLine', { bg = c.bg_sel })
  hl('CursorColumn', { bg = c.bg_sel })
  hl('ColorColumn', { bg = c.bg_dark })

  hl('LineNr', { fg = c.linenr, bg = c.bg_dark })
  hl('CursorLineNr', { fg = c.fg_dark, bg = c.bg, bold = true })
  hl('SignColumn', { bg = c.bg })
  hl('FoldColumn', { fg = c.fg_dark, bg = c.bg })
  hl('Folded', { fg = c.fg_dark, bg = c.bg_sel })

  -- Status line
  hl('StatusLine', { fg = c.fg_dark })
  hl('StatusLineNC', { fg = c.bg, bg = c.fg_dark })
  hl('VertSplit', { fg = c.border })
  hl('WinSeparator', { fg = c.border })

  -- Search and selection
  hl('Visual', { bg = c.bg_sel })
  hl('VisualNOS', { bg = c.bg_sel })
  hl('Search', { fg = c.bg, bg = c.yellow, bold = true })
  hl('IncSearch', { fg = c.bg, bg = c.orange, bold = true })
  hl('CurSearch', { fg = c.bg, bg = c.orange_br, bold = true })
  hl('Substitute', { fg = c.bg, bg = c.red, bold = true })

  -- Messages and prompts
  hl('ErrorMsg', { fg = c.red_br, bold = true })
  hl('WarningMsg', { fg = c.orange, bold = true })
  hl('ModeMsg', { fg = c.green, bold = true })
  hl('MoreMsg', { fg = c.green, bold = true })
  hl('Question', { fg = c.blue, bold = true })
  hl('Title', { fg = c.blue, bold = true })
  hl('Directory', { fg = c.blue })
  hl('NonText', { fg = c.fg_dark })
  hl('EndOfBuffer', { fg = c.bg })
  hl('SpecialKey', { fg = c.fg_dark })
  hl('Whitespace', { fg = c.bg_sel })

  -- Popup menu
  hl('Pmenu', { fg = c.fg, bg = c.bg_light })
  hl('PmenuSel', { fg = c.bg, bg = c.blue, bold = true })
  hl('PmenuKind', { fg = c.yellow, bg = c.bg_light })
  hl('PmenuKindSel', { fg = c.bg, bg = c.blue, bold = true })  -- Darker fg for AA compliance
  hl('PmenuExtra', { fg = c.fg_dark, bg = c.bg_light })
  hl('PmenuExtraSel', { fg = c.bg, bg = c.blue })  -- Darker fg for AA compliance
  hl('PmenuSbar', { bg = c.bg_light })
  hl('PmenuThumb', { fg = c.border, bg = c.bg_light })  -- Fixed for AA compliance

  -- Tabs
  hl('TabLine', { fg = c.fg_dark, bg = c.bg_sel })
  hl('TabLineFill', { bg = c.bg })
  hl('TabLineSel', { fg = c.green, bg = c.bg, bold = true })

  -- Diffs
  hl('DiffAdd', { fg = c.green, bg = c.bg_sel })
  hl('DiffChange', { fg = c.orange, bg = c.bg_sel })
  hl('DiffDelete', { fg = c.red, bg = c.bg_sel })
  hl('DiffText', { fg = c.yellow, bg = c.bg_sel, bold = true })

  hl('diffAdded', { fg = c.green })
  hl('diffRemoved', { fg = c.red })
  hl('diffChanged', { fg = c.orange })
  hl('diffOldFile', { fg = c.red })
  hl('diffNewFile', { fg = c.green })
  hl('diffFile', { fg = c.blue })
  hl('diffLine', { fg = c.cyan })
  hl('diffIndexLine', { fg = c.magenta })

  -- ============================================================================
  -- SYNTAX HIGHLIGHTING
  -- ============================================================================

  hl('Comment', { fg = c.fg_dark, italic = true })
  hl('SpecialComment', { fg = c.cyan, italic = true })

  hl('Constant', { fg = c.orange })
  hl('String', { fg = c.green })
  hl('Character', { fg = c.green })
  hl('Number', { fg = c.orange })
  hl('Boolean', { fg = c.orange })
  hl('Float', { fg = c.orange })

  hl('Identifier', { fg = c.fg })
  hl('Function', { fg = c.blue })

  hl('Statement', { fg = c.magenta, italic = true })
  hl('Conditional', { fg = c.magenta, italic = true })
  hl('Repeat', { fg = c.magenta, italic = true })
  hl('Label', { fg = c.magenta, italic = true })
  hl('Operator', { fg = c.fg })
  hl('Keyword', { fg = c.magenta, italic = true })
  hl('Exception', { fg = c.red, italic = true })

  hl('PreProc', { fg = c.cyan })
  hl('Include', { fg = c.magenta, italic = true })
  hl('Define', { fg = c.magenta, italic = true })
  hl('Macro', { fg = c.cyan })
  hl('PreCondit', { fg = c.cyan })

  hl('Type', { fg = c.yellow })
  hl('StorageClass', { fg = c.yellow, italic = true })
  hl('Structure', { fg = c.yellow })
  hl('Typedef', { fg = c.yellow, italic = true })

  hl('Special', { fg = c.cyan })
  hl('SpecialChar', { fg = c.accent })
  hl('Tag', { fg = c.yellow })
  hl('Delimiter', { fg = c.accent })
  hl('Debug', { fg = c.red })

  hl('Underlined', { fg = c.blue, underline = true })
  hl('Ignore', { fg = c.bg })
  hl('Error', { fg = c.red_br, bg = c.bg_dark, bold = true })
  hl('Todo', { fg = c.yellow, bg = c.bg_sel, bold = true })

  -- ============================================================================
  -- DIAGNOSTICS
  -- ============================================================================

  hl('DiagnosticError', { fg = c.red })
  hl('DiagnosticWarn', { fg = c.orange })
  hl('DiagnosticInfo', { fg = c.blue })
  hl('DiagnosticHint', { fg = c.cyan })
  hl('DiagnosticOk', { fg = c.green })

  hl('DiagnosticSignError', { fg = c.red, bg = c.bg })
  hl('DiagnosticSignWarn', { fg = c.orange, bg = c.bg })
  hl('DiagnosticSignInfo', { fg = c.blue, bg = c.bg })
  hl('DiagnosticSignHint', { fg = c.cyan, bg = c.bg })
  hl('DiagnosticSignOk', { fg = c.green, bg = c.bg })

  hl('DiagnosticVirtualTextError', { fg = c.red })
  hl('DiagnosticVirtualTextWarn', { fg = c.orange })
  hl('DiagnosticVirtualTextInfo', { fg = c.blue })
  hl('DiagnosticVirtualTextHint', { fg = c.cyan })

  hl('DiagnosticUnderlineError', { sp = c.red, underline = true })
  hl('DiagnosticUnderlineWarn', { sp = c.orange, underline = true })
  hl('DiagnosticUnderlineInfo', { sp = c.blue, underline = true })
  hl('DiagnosticUnderlineHint', { sp = c.cyan, underline = true })

  hl('DiagnosticFloatingError', { fg = c.red, bg = c.bg_light })
  hl('DiagnosticFloatingWarn', { fg = c.orange, bg = c.bg_light })
  hl('DiagnosticFloatingInfo', { fg = c.blue, bg = c.bg_light })
  hl('DiagnosticFloatingHint', { fg = c.cyan, bg = c.bg_light })

  -- ============================================================================
  -- LSP
  -- ============================================================================

  hl('LspReferenceText', { bg = c.bg_sel })
  hl('LspReferenceRead', { bg = c.bg_sel })
  hl('LspReferenceWrite', { bg = c.bg_sel, bold = true })
  hl('LspCodeLens', { fg = c.fg_dark, italic = true })
  hl('LspCodeLensSeparator', { fg = c.fg_dark })
  hl('LspSignatureActiveParameter', { fg = c.yellow, bold = true })

  -- LSP Semantic tokens
  hl('LspInlayHint', { fg = c.fg_dark, bg = c.bg, italic = true })
  hl('@lsp.type.namespace', { fg = c.cyan })
  hl('@lsp.type.type', { fg = c.yellow })
  hl('@lsp.type.class', { fg = c.yellow })
  hl('@lsp.type.enum', { fg = c.yellow })
  hl('@lsp.type.interface', { fg = c.yellow, italic = true })
  hl('@lsp.type.struct', { fg = c.yellow })
  hl('@lsp.type.parameter', { fg = c.red })
  hl('@lsp.type.variable', { fg = c.fg })
  hl('@lsp.type.property', { fg = c.red })
  hl('@lsp.type.enumMember', { fg = c.cyan })
  hl('@lsp.type.function', { fg = c.blue })
  hl('@lsp.type.method', { fg = c.blue })
  hl('@lsp.type.macro', { fg = c.cyan })
  hl('@lsp.type.decorator', { fg = c.cyan })
  hl('@lsp.mod.readonly', { fg = c.orange })
  hl('@lsp.mod.typeHint', { fg = c.fg_dark, italic = true })
  hl('@lsp.mod.defaultLibrary', { fg = c.cyan, italic = true })
  hl('@lsp.typemod.function.defaultLibrary', { fg = c.cyan })
  hl('@lsp.typemod.variable.defaultLibrary', { fg = c.orange })
  hl('@lsp.typemod.variable.global', { fg = c.orange })
  hl('@lsp.typemod.variable.static', { fg = c.orange, italic = true })

  -- ============================================================================
  -- TREESITTER
  -- ============================================================================

  -- Variables
  hl('@variable', { fg = c.fg })
  hl('@variable.builtin', { fg = c.orange, italic = true })
  hl('@variable.parameter', { fg = c.red })
  hl('@variable.parameter.builtin', { fg = c.orange })
  hl('@variable.member', { fg = c.red })

  -- Constants
  hl('@constant', { fg = c.orange })
  hl('@constant.builtin', { fg = c.orange })
  hl('@constant.macro', { fg = c.cyan })
  hl('@module', { fg = c.cyan })
  hl('@module.builtin', { fg = c.orange })

  -- Strings
  hl('@string', { fg = c.green })
  hl('@string.documentation', { fg = c.green, italic = true })
  hl('@string.escape', { fg = c.cyan })
  hl('@string.regexp', { fg = c.cyan })
  hl('@string.special', { fg = c.accent })
  hl('@string.special.symbol', { fg = c.red })
  hl('@string.special.url', { fg = c.blue, underline = true })
  hl('@string.special.path', { fg = c.cyan })

  -- Characters and Numbers
  hl('@character', { fg = c.green })
  hl('@character.special', { fg = c.cyan })
  hl('@number', { fg = c.orange })
  hl('@number.float', { fg = c.orange })
  hl('@boolean', { fg = c.orange })

  -- Functions
  hl('@function', { fg = c.blue })
  hl('@function.builtin', { fg = c.cyan })
  hl('@function.call', { fg = c.blue })
  hl('@function.macro', { fg = c.cyan })
  hl('@function.method', { fg = c.blue })
  hl('@function.method.call', { fg = c.blue })
  hl('@constructor', { fg = c.cyan })

  -- Keywords
  hl('@keyword', { fg = c.magenta, italic = true })
  hl('@keyword.coroutine', { fg = c.magenta, italic = true })
  hl('@keyword.function', { fg = c.magenta, italic = true })
  hl('@keyword.operator', { fg = c.magenta, italic = true })
  hl('@keyword.import', { fg = c.magenta, italic = true })
  hl('@keyword.type', { fg = c.magenta, italic = true })
  hl('@keyword.modifier', { fg = c.magenta, italic = true })
  hl('@keyword.repeat', { fg = c.magenta, italic = true })
  hl('@keyword.return', { fg = c.magenta, italic = true })
  hl('@keyword.debug', { fg = c.red, italic = true })
  hl('@keyword.exception', { fg = c.red, italic = true })
  hl('@keyword.conditional', { fg = c.magenta, italic = true })
  hl('@keyword.conditional.ternary', { fg = c.magenta })
  hl('@keyword.directive', { fg = c.magenta, italic = true })
  hl('@keyword.directive.define', { fg = c.magenta, italic = true })

  -- Control flow
  hl('@conditional', { fg = c.magenta, italic = true })
  hl('@repeat', { fg = c.magenta, italic = true })
  hl('@label', { fg = c.magenta })
  hl('@operator', { fg = c.fg })
  hl('@exception', { fg = c.red, italic = true })

  -- Types
  hl('@type', { fg = c.yellow })
  hl('@type.builtin', { fg = c.yellow, italic = true })
  hl('@type.definition', { fg = c.yellow })
  hl('@type.qualifier', { fg = c.magenta, italic = true })
  hl('@attribute', { fg = c.cyan })
  hl('@attribute.builtin', { fg = c.cyan })

  -- Properties and fields
  hl('@property', { fg = c.red })
  hl('@field', { fg = c.red })
  hl('@parameter', { fg = c.red })

  -- Comments
  hl('@comment', { fg = c.fg_dark, italic = true })
  hl('@comment.documentation', { fg = c.cyan, italic = true })
  hl('@comment.error', { fg = c.red, bold = true, italic = true })
  hl('@comment.warning', { fg = c.orange, bold = true, italic = true })
  hl('@comment.todo', { fg = c.yellow, bold = true, italic = true })
  hl('@comment.note', { fg = c.blue, bold = true, italic = true })

  -- Punctuation
  hl('@punctuation.delimiter', { fg = c.accent })
  hl('@punctuation.bracket', { fg = c.fg })
  hl('@punctuation.special', { fg = c.cyan })

  -- Markup (Markdown, etc.)
  hl('@markup.strong', { fg = c.fg, bold = true })
  hl('@markup.italic', { fg = c.fg, italic = true })
  hl('@markup.strikethrough', { fg = c.fg_dark, strikethrough = true })
  hl('@markup.underline', { fg = c.fg, underline = true })
  hl('@markup.heading', { fg = c.blue, bold = true })
  hl('@markup.heading.1', { fg = c.blue, bold = true })
  hl('@markup.heading.2', { fg = c.cyan, bold = true })
  hl('@markup.heading.3', { fg = c.green, bold = true })
  hl('@markup.heading.4', { fg = c.yellow, bold = true })
  hl('@markup.heading.5', { fg = c.orange, bold = true })
  hl('@markup.heading.6', { fg = c.magenta, bold = true })
  hl('@markup.quote', { fg = c.fg_dark, italic = true })
  hl('@markup.math', { fg = c.cyan })
  hl('@markup.link', { fg = c.blue, underline = true })
  hl('@markup.link.label', { fg = c.cyan })
  hl('@markup.link.url', { fg = c.blue, underline = true })
  hl('@markup.raw', { fg = c.green })
  hl('@markup.raw.block', { fg = c.green })
  hl('@markup.list', { fg = c.magenta })
  hl('@markup.list.checked', { fg = c.green })
  hl('@markup.list.unchecked', { fg = c.fg_dark })

  -- Tags (HTML, JSX, etc.)
  hl('@tag', { fg = c.cyan })
  hl('@tag.builtin', { fg = c.cyan })
  hl('@tag.attribute', { fg = c.yellow })
  hl('@tag.delimiter', { fg = c.accent })

  -- Diff
  hl('@diff.plus', { fg = c.green })
  hl('@diff.minus', { fg = c.red })
  hl('@diff.delta', { fg = c.orange })

  -- ============================================================================
  -- GIT SIGNS & GIT GUTTER
  -- ============================================================================

  hl('GitSignsAdd', { fg = c.green, bg = c.bg })
  hl('GitSignsChange', { fg = c.orange, bg = c.bg })
  hl('GitSignsDelete', { fg = c.red, bg = c.bg })
  hl('GitSignsAddNr', { fg = c.green })
  hl('GitSignsChangeNr', { fg = c.orange })
  hl('GitSignsDeleteNr', { fg = c.red })
  hl('GitSignsAddLn', { bg = c.bg_sel })
  hl('GitSignsChangeLn', { bg = c.bg_sel })
  hl('GitSignsDeleteLn', { bg = c.bg_sel })

  -- Mark highlights as loaded
  _cache.highlights_loaded = true

  -- Load plugin highlights lazily if not disabled
  if not opts.disable_plugin_highlights then
    M.load_plugin_highlights(opts.plugins)
  end
end

-- Load plugin highlights on demand
function M.load_plugin_highlights(plugins)
  -- Lazy load plugin highlights
  vim.defer_fn(function()
    local c = get_colors()
    require('mapledark.plugins').setup(c, plugins, _cache.plugins_loaded)
  end, 0)
end

-- Load specific plugin highlight on demand
function M.load_plugin(plugin_name)
  if _cache.plugins_loaded[plugin_name] then
    return -- Already loaded
  end

  local c = get_colors()
  local plugins = require('mapledark.plugins')

  if plugins.loaders[plugin_name] then
    plugins.loaders[plugin_name](c)
    _cache.plugins_loaded[plugin_name] = true
  end
end

-- Clear cache (useful for theme development)
function M.clear_cache()
  _cache = {
    colors = nil,
    highlights_loaded = false,
    plugins_loaded = {},
  }
end

-- Reload theme with cache clearing
function M.reload()
  M.clear_cache()
  M.setup({ force = true })
end

-- Load the colorscheme
function M.load()
  M.setup()
end

return M

