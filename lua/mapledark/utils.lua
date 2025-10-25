-- Shared utilities for Maple Dark theme
-- Common functions used across modules

local M = {}

-- Single highlight function used everywhere
function M.hl(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- Batch set highlights for better performance
function M.hl_batch(highlights)
  for group, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

-- Helper to create highlight groups with consistent formatting
function M.create_highlights(definitions, colors)
  for group, opts in pairs(definitions) do
    -- Allow color substitution from color table
    local processed_opts = {}
    for key, value in pairs(opts) do
      if type(value) == 'string' and value:match('^%$') then
        -- Replace $colorname with actual color
        local color_name = value:sub(2)
        processed_opts[key] = colors[color_name]
      else
        processed_opts[key] = value
      end
    end
    M.hl(group, processed_opts)
  end
end

-- Common highlight pattern: simple fg color
function M.fg(group, color)
  M.hl(group, { fg = color })
end

-- Common highlight pattern: fg + bg
function M.fg_bg(group, fg, bg, opts)
  opts = opts or {}
  opts.fg = fg
  opts.bg = bg
  M.hl(group, opts)
end

-- Common highlight pattern: bold
function M.bold(group, color)
  M.hl(group, { fg = color, bold = true })
end

-- Common highlight pattern: italic
function M.italic(group, color)
  M.hl(group, { fg = color, italic = true })
end

-- Common highlight pattern: underline
function M.underline(group, color)
  M.hl(group, { fg = color, underline = true })
end

-- Link one highlight group to another
function M.link(from, to)
  vim.api.nvim_set_hl(0, from, { link = to })
end

-- Create multiple links at once
function M.link_many(links)
  for from, to in pairs(links) do
    M.link(from, to)
  end
end

-- Validate color format
function M.is_valid_color(color)
  return type(color) == 'string' and color:match('^#%x%x%x%x%x%x$')
end

-- Validate highlight options
function M.validate_highlight(opts)
  local valid_keys = {
    fg = true, bg = true, sp = true,
    bold = true, italic = true, underline = true,
    undercurl = true, underdouble = true, underdotted = true, underdashed = true,
    strikethrough = true, reverse = true, standout = true,
    blend = true, link = true
  }

  for key in pairs(opts) do
    if not valid_keys[key] then
      error(string.format('Invalid highlight option: %s', key), 2)
    end
  end

  return true
end

-- Debug helper to print highlight group
function M.debug_hl(group)
  local hl = vim.api.nvim_get_hl(0, { name = group })
  print(string.format('Highlight: %s', group))
  for k, v in pairs(hl) do
    print(string.format('  %s = %s', k, vim.inspect(v)))
  end
end

return M

