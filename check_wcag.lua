#!/usr/bin/env lua
-- WCAG Color Contrast Checker for Maple Dark Neovim Theme
-- Checks all highlight groups against WCAG AA and AAA standards
--
-- Usage:
--   lua check_wcag.lua
--   or
--   nvim --headless -c "luafile check_wcag.lua" -c "qa"
--
-- The script will:
--   1. Parse all highlight groups from lua/mapledark/init.lua and plugins.lua
--   2. Resolve color references (e.g., c.fg, c.bg_dark) to hex values
--   3. Calculate contrast ratios for all fg/bg combinations
--   4. Check against WCAG standards:
--      - AA Normal: ≥4.5:1
--      - AA Large: ≥3.0:1
--      - AAA Normal: ≥7.0:1
--      - AAA Large: ≥4.5:1
--   5. Print a detailed report of all results
--
-- Exit codes:
--   0: All highlight groups pass WCAG AA standards
--   1: One or more highlight groups fail WCAG AA standards

local M = {}

-- WCAG contrast ratio requirements
local WCAG_AA_NORMAL = 4.5  -- Normal text (smaller than 18pt or 14pt bold)
local WCAG_AA_LARGE = 3.0   -- Large text (18pt+ or 14pt+ bold)
local WCAG_AAA_NORMAL = 7.0 -- Normal text AAA
local WCAG_AAA_LARGE = 4.5  -- Large text AAA

-- Highlight group structure
local HighlightGroup = {}
HighlightGroup.__index = HighlightGroup

function HighlightGroup.new(name, fg, bg, bold, source_file)
  local self = setmetatable({}, HighlightGroup)
  self.name = name
  self.fg = fg
  self.bg = bg
  self.bold = bold or false
  self.source_file = source_file or ""
  return self
end

-- Contrast result structure
local ContrastResult = {}
ContrastResult.__index = ContrastResult

function ContrastResult.new(highlight, ratio)
  local self = setmetatable({}, ContrastResult)
  self.highlight = highlight
  self.ratio = ratio
  self.passes_aa_normal = ratio >= WCAG_AA_NORMAL
  self.passes_aa_large = ratio >= WCAG_AA_LARGE
  self.passes_aaa_normal = ratio >= WCAG_AAA_NORMAL
  self.passes_aaa_large = ratio >= WCAG_AAA_LARGE
  return self
end

-- WCAG Checker class
local WCAGChecker = {}
WCAGChecker.__index = WCAGChecker

function WCAGChecker.new(project_root)
  local self = setmetatable({}, WCAGChecker)
  self.project_root = project_root
  self.colors = {}
  self.highlights = {}
  self:_load_colors()
  return self
end

function WCAGChecker:_load_colors()
  -- Load color definitions from init.lua
  local init_file = (self.project_root or ".") .. "/lua/mapledark/init.lua"
  local file = io.open(init_file, "r")
  if not file then
    error("Could not find " .. init_file .. " (project_root: " .. tostring(self.project_root) .. ")")
  end

  local content = file:read("*a")
  file:close()

  -- Pattern to match color definitions like: bg_dark = '#1a1a1b',
  local color_pattern = "(%w+)%s*=%s*['\"](#[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])['\"]"

  -- Find the colors table section
  local colors_start = content:find("_cache%.colors = {")
  if not colors_start then
    colors_start = content:find("colors = {")
  end

  if colors_start then
    -- Extract the colors block (find matching closing brace)
    local brace_count = 0
    local start_pos = colors_start
    local colors_block = ""

    for i = start_pos, #content do
      local char = content:sub(i, i)
      if char == "{" then
        brace_count = brace_count + 1
      elseif char == "}" then
        brace_count = brace_count - 1
        if brace_count == 0 then
          colors_block = content:sub(start_pos, i)
          break
        end
      end
    end

    -- Extract all color definitions
    for name, hex_color in colors_block:gmatch(color_pattern) do
      self.colors[name] = hex_color:lower()
    end
  end
end

function WCAGChecker:_resolve_color(color_ref)
  -- Resolve color reference like 'c.fg' or '#ffffff' to hex
  if not color_ref or color_ref == "" then
    return nil
  end

  -- If it's already a hex color, return it
  if color_ref:match("^#") then
    return color_ref:lower()
  end

  -- If it's a color reference like 'c.fg' or 'c.bg_dark'
  local color_name = color_ref:match("^c%.(.+)$")
  if color_name then
    return self.colors[color_name]
  end

  -- Try direct lookup
  return self.colors[color_ref]
end

function WCAGChecker:_parse_highlight(line, source_file)
  -- Parse a highlight definition line
  -- Pattern: hl('GroupName', { fg = c.fg, bg = c.bg, bold = true })
  local pattern = "hl%(['\"]([^'\"]+)['\"],%s*%{([^}]+)%}%)"
  local group_name, opts_str = line:match(pattern)

  if not group_name then
    return nil
  end

  -- Extract options
  local fg = nil
  local bg = nil
  local bold = false

  -- Extract fg
  local fg_match = opts_str:match("fg%s*=%s*([^,}]+)")
  if fg_match then
    local fg_raw = fg_match:gsub("^%s+", ""):gsub("%s+$", ""):gsub("['\"]", "")
    fg = self:_resolve_color(fg_raw)
  end

  -- Extract bg
  local bg_match = opts_str:match("bg%s*=%s*([^,}]+)")
  if bg_match then
    local bg_raw = bg_match:gsub("^%s+", ""):gsub("%s+$", ""):gsub("['\"]", "")
    bg = self:_resolve_color(bg_raw)
  end

  -- Extract bold
  if opts_str:match("bold%s*=%s*true") then
    bold = true
  end

  return HighlightGroup.new(group_name, fg, bg, bold, source_file)
end

function WCAGChecker:_load_highlights()
  -- Load all highlight groups from Lua files
  local lua_dir = (self.project_root or ".") .. "/lua/mapledark"

  -- Files to check
  local files_to_check = {
    "init.lua",
    "plugins.lua"
  }

  for _, filename in ipairs(files_to_check) do
    local filepath = lua_dir .. "/" .. filename
    local file = io.open(filepath, "r")
    if file then
      for line in file:lines() do
        local highlight = self:_parse_highlight(line, filename)
        if highlight then
          table.insert(self.highlights, highlight)
        end
      end
      file:close()
    end
  end
end

function WCAGChecker:_hex_to_rgb(hex_color)
  -- Convert hex color to RGB tuple
  hex_color = hex_color:gsub("#", "")
  local r = tonumber(hex_color:sub(1, 2), 16)
  local g = tonumber(hex_color:sub(3, 4), 16)
  local b = tonumber(hex_color:sub(5, 6), 16)
  return r, g, b
end

function WCAGChecker:_get_luminance(r, g, b)
  -- Calculate relative luminance according to WCAG
  local function normalize(value)
    local val = value / 255.0
    if val <= 0.03928 then
      return val / 12.92
    end
    return math.pow((val + 0.055) / 1.055, 2.4)
  end

  local r_norm = normalize(r)
  local g_norm = normalize(g)
  local b_norm = normalize(b)

  return 0.2126 * r_norm + 0.7152 * g_norm + 0.0722 * b_norm
end

function WCAGChecker:_get_contrast_ratio(color1, color2)
  -- Calculate contrast ratio between two colors
  local r1, g1, b1 = self:_hex_to_rgb(color1)
  local r2, g2, b2 = self:_hex_to_rgb(color2)

  local lum1 = self:_get_luminance(r1, g1, b1)
  local lum2 = self:_get_luminance(r2, g2, b2)

  local lighter = math.max(lum1, lum2)
  local darker = math.min(lum1, lum2)

  return (lighter + 0.05) / (darker + 0.05)
end

function WCAGChecker:check_contrast(highlight)
  -- Check contrast ratio for a highlight group
  -- Need both fg and bg to calculate contrast
  if not highlight.fg or not highlight.bg then
    return nil
  end

  local ratio = self:_get_contrast_ratio(highlight.fg, highlight.bg)
  return ContrastResult.new(highlight, ratio)
end

function WCAGChecker:check_all()
  -- Check all highlight groups
  self:_load_highlights()
  local results = {}

  for _, highlight in ipairs(self.highlights) do
    local result = self:check_contrast(highlight)
    if result then
      table.insert(results, result)
    end
  end

  return results
end

function WCAGChecker:print_report(results)
  -- Print a formatted report
  if #results == 0 then
    print("No highlight groups with both foreground and background colors found.")
    return
  end

  -- Sort by ratio (lowest first - most problematic)
  table.sort(results, function(a, b) return a.ratio < b.ratio end)

  print(string.rep("=", 80))
  print("WCAG COLOR CONTRAST COMPLIANCE REPORT")
  print(string.rep("=", 80))
  print(string.format("\nTotal highlight groups checked: %d\n", #results))

  -- Group results by compliance level
  local aa_normal_failures = {}
  local aa_large_failures = {}
  local aaa_normal_failures = {}
  local aaa_large_failures = {}

  for _, result in ipairs(results) do
    if not result.passes_aa_normal then
      table.insert(aa_normal_failures, result)
    end
    if not result.passes_aa_large then
      table.insert(aa_large_failures, result)
    end
    if not result.passes_aaa_normal then
      table.insert(aaa_normal_failures, result)
    end
    if not result.passes_aaa_large then
      table.insert(aaa_large_failures, result)
    end
  end

  -- Print summary
  print("SUMMARY:")
  print(string.format("  WCAG AA (Normal text, ≥4.5:1): %d/%d pass", #results - #aa_normal_failures, #results))
  print(string.format("  WCAG AA (Large text, ≥3.0:1):  %d/%d pass", #results - #aa_large_failures, #results))
  print(string.format("  WCAG AAA (Normal text, ≥7.0:1): %d/%d pass", #results - #aaa_normal_failures, #results))
  print(string.format("  WCAG AAA (Large text, ≥4.5:1): %d/%d pass", #results - #aaa_large_failures, #results))
  print()

  -- Print failures
  if #aa_normal_failures > 0 then
    print(string.rep("=", 80))
    print("FAILURES - WCAG AA (Normal Text, ≥4.5:1)")
    print(string.rep("=", 80))
    for _, result in ipairs(aa_normal_failures) do
      local h = result.highlight
      print(string.format("\n  %s", h.name))
      print(string.format("    File: %s", h.source_file))
      print(string.format("    Colors: fg=%s bg=%s", h.fg or "nil", h.bg or "nil"))
      print(string.format("    Contrast Ratio: %.2f:1", result.ratio))
      print(string.format("    Bold: %s", tostring(h.bold)))
      print(string.format("    Status: %s", result.passes_aa_large and "PASS (Large text)" or "FAIL"))
    end
  end

  if #aaa_normal_failures > 0 then
    print("\n" .. string.rep("=", 80))
    print("FAILURES - WCAG AAA (Normal Text, ≥7.0:1)")
    print(string.rep("=", 80))
    for _, result in ipairs(aaa_normal_failures) do
      local h = result.highlight
      print(string.format("\n  %s", h.name))
      print(string.format("    File: %s", h.source_file))
      print(string.format("    Colors: fg=%s bg=%s", h.fg or "nil", h.bg or "nil"))
      print(string.format("    Contrast Ratio: %.2f:1", result.ratio))
      print(string.format("    Bold: %s", tostring(h.bold)))
      print(string.format("    Status: %s", result.passes_aaa_large and "PASS (Large text)" or "FAIL"))
    end
  end

  -- Print all results in a table
  print("\n" .. string.rep("=", 80))
  print("ALL HIGHLIGHT GROUPS - DETAILED RESULTS")
  print(string.rep("=", 80))
  print(string.format("\n%-40s %-10s %-8s %-8s %s", "Highlight Group", "Ratio", "AA", "AAA", "Colors"))
  print(string.rep("-", 80))

  -- Sort by name for the table
  table.sort(results, function(a, b) return a.highlight.name < b.highlight.name end)

  for _, result in ipairs(results) do
    local h = result.highlight
    local aa_status = result.passes_aa_normal and "✓" or (result.passes_aa_large and "L" or "✗")
    local aaa_status = result.passes_aaa_normal and "✓" or (result.passes_aaa_large and "L" or "✗")
    local colors_str = string.format("%s / %s", h.fg or "nil", h.bg or "nil")

    print(string.format("%-40s %6.2f:1  %-8s %-8s %s", h.name, result.ratio, aa_status, aaa_status, colors_str))
  end

  print()
end

-- Main execution
local function main()
  -- Get project root (current directory where script is run)
  local project_root = "."

  -- If running from Neovim, try to get the actual project root
  if vim and vim.fn then
    project_root = vim.fn.fnamemodify(vim.fn.expand("%:p:h"), ":h")
  else
    -- Try to detect script location
    local info = debug.getinfo(1, "S")
    if info and info.source then
      local script_path = info.source
      if script_path:match("^@") then
        script_path = script_path:gsub("^@", "")
        local dir = script_path:match("^(.*)/")
        if dir then
          project_root = dir
        end
      end
    end
  end

  -- Fallback to current directory
  if not project_root or project_root == "" then
    project_root = "."
  end

  local checker = WCAGChecker.new(project_root)
  local results = checker:check_all()
  checker:print_report(results)

  -- Exit with error code if there are failures
  local aa_failures = 0
  for _, result in ipairs(results) do
    if not result.passes_aa_normal then
      aa_failures = aa_failures + 1
    end
  end

  if aa_failures > 0 then
    os.exit(1)
  end
end

-- Run if executed directly
if not package.loaded["check_wcag"] then
  main()
end

return M

