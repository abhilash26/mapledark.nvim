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

function ContrastResult.new(highlight, ratio, actual_fg, actual_bg)
  local self = setmetatable({}, ContrastResult)
  self.highlight = highlight
  self.ratio = ratio
  self.actual_fg = actual_fg  -- The actual fg color used for calculation
  self.actual_bg = actual_bg  -- The actual bg color used for calculation
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
  self.normal_fg = nil
  self.normal_bg = nil
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
  local fg_is_none = false
  local bg_is_none = false

  -- Extract fg
  local fg_match = opts_str:match("fg%s*=%s*([^,}]+)")
  if fg_match then
    local fg_raw = fg_match:gsub("^%s+", ""):gsub("%s+$", ""):gsub("['\"]", "")
    -- Check if it's "none"
    if fg_raw == "none" then
      fg_is_none = true
      fg = nil
    else
      fg = self:_resolve_color(fg_raw)
    end
  end

  -- Extract bg
  local bg_match = opts_str:match("bg%s*=%s*([^,}]+)")
  if bg_match then
    local bg_raw = bg_match:gsub("^%s+", ""):gsub("%s+$", ""):gsub("['\"]", "")
    -- Check if it's "none"
    if bg_raw == "none" then
      bg_is_none = true
      bg = nil
    else
      bg = self:_resolve_color(bg_raw)
    end
  end

  -- Extract bold
  if opts_str:match("bold%s*=%s*true") then
    bold = true
  end

  -- Store Normal highlight colors for reference
  if group_name == "Normal" then
    self.normal_fg = fg or self.colors.fg
    self.normal_bg = bg or self.colors.bg_dark or self.colors.bg
  end

  local highlight = HighlightGroup.new(group_name, fg, bg, bold, source_file)
  highlight.fg_is_none = fg_is_none
  highlight.bg_is_none = bg_is_none
  return highlight
end

function WCAGChecker:_load_highlights()
  -- Load all highlight groups from Lua files
  local lua_dir = (self.project_root or ".") .. "/lua/mapledark"

  -- Files to check
  local files_to_check = {
    "init.lua",
    "plugins.lua"
  }

  -- First pass: find Normal highlight to get its colors
  for _, filename in ipairs(files_to_check) do
    local filepath = lua_dir .. "/" .. filename
    local file = io.open(filepath, "r")
    if file then
      for line in file:lines() do
        local highlight = self:_parse_highlight(line, filename)
        if highlight and highlight.name == "Normal" then
          -- Normal found, colors are stored in self.normal_fg and self.normal_bg
          break
        end
      end
      file:close()
    end
  end

  -- Second pass: load all highlights (now Normal colors are known)
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
  -- Use Normal highlight colors when fg/bg is "none" (transparent)
  local fg = highlight.fg
  local bg = highlight.bg

  -- Get Normal highlight colors (fallback to defaults if Normal not found yet)
  local normal_fg = self.normal_fg or self.colors.fg or "#cbd5e1"
  local normal_bg = self.normal_bg or self.colors.bg_dark or self.colors.bg or "#1e1e1f"

  -- If foreground is "none" or missing, use Normal's foreground
  if highlight.fg_is_none or not fg then
    fg = normal_fg
  end

  -- If background is "none" or missing, use Normal's background
  if highlight.bg_is_none or not bg then
    bg = normal_bg
  end

  -- If still no colors, can't check
  if not fg or not bg then
    return nil
  end

  -- Skip highlights where fg and bg are intentionally the same (like Ignore, EndOfBuffer)
  -- These are meant to be invisible and don't need contrast checking
  if fg == bg then
    return nil
  end

  local ratio = self:_get_contrast_ratio(fg, bg)
  return ContrastResult.new(highlight, ratio, fg, bg)
end

function WCAGChecker:check_all()
  -- Check all highlight groups
  self:_load_highlights()
  local results = {}
  local unchecked = {}

  for _, highlight in ipairs(self.highlights) do
    local result = self:check_contrast(highlight)
    if result then
      table.insert(results, result)
    else
      table.insert(unchecked, highlight)
    end
  end

  return results, unchecked
end

function WCAGChecker:print_report(results, unchecked)
  -- Print a formatted report
  unchecked = unchecked or {}

  if #results == 0 and #unchecked == 0 then
    print("No highlight groups found.")
    return
  end

  -- Sort by ratio (lowest first - most problematic)
  table.sort(results, function(a, b) return a.ratio < b.ratio end)

  print(string.rep("=", 80))
  print("WCAG COLOR CONTRAST COMPLIANCE REPORT")
  print(string.rep("=", 80))
  print(string.format("\nTotal highlight groups found: %d", #results + #unchecked))
  print(string.format("Highlight groups checked: %d", #results))
  if #unchecked > 0 then
    print(string.format("Highlight groups unchecked (no colors): %d", #unchecked))
  end
  print()

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

  -- Count highlights by file
  local highlights_by_file = {}
  for _, result in ipairs(results) do
    local file = result.highlight.source_file
    highlights_by_file[file] = (highlights_by_file[file] or 0) + 1
  end

  -- Print summary
  print("SUMMARY:")
  print(string.format("  WCAG AA (Normal text, ≥4.5:1): %d/%d pass", #results - #aa_normal_failures, #results))
  print(string.format("  WCAG AA (Large text, ≥3.0:1):  %d/%d pass", #results - #aa_large_failures, #results))
  print(string.format("  WCAG AAA (Normal text, ≥7.0:1): %d/%d pass", #results - #aaa_normal_failures, #results))
  print(string.format("  WCAG AAA (Large text, ≥4.5:1): %d/%d pass", #results - #aaa_large_failures, #results))
  print()

  -- Print highlights by file
  print("HIGHLIGHTS BY FILE:")
  for file, count in pairs(highlights_by_file) do
    print(string.format("  %s: %d highlight groups", file, count))
  end
  print()

  -- Print failures section
  local total_failures = #aa_normal_failures + #aa_large_failures + #aaa_normal_failures + #aaa_large_failures

  if total_failures > 0 then
    print(string.rep("=", 80))
    print("FAILURES SUMMARY")
    print(string.rep("=", 80))
    print(string.format("  WCAG AA Normal failures: %d", #aa_normal_failures))
    print(string.format("  WCAG AA Large failures: %d", #aa_large_failures))
    print(string.format("  WCAG AAA Normal failures: %d", #aaa_normal_failures))
    print(string.format("  WCAG AAA Large failures: %d", #aaa_large_failures))
    print()
  end

  if #aa_normal_failures > 0 then
    print(string.rep("=", 80))
    print("FAILURES - WCAG AA (Normal Text, ≥4.5:1)")
    print(string.rep("=", 80))
    for _, result in ipairs(aa_normal_failures) do
      local h = result.highlight
      print(string.format("\n  %s", h.name))
      print(string.format("    File: %s", h.source_file))
      local fg_display = result.actual_fg or h.fg or "(none)"
      local bg_display = result.actual_bg or h.bg or "(none)"
      if h.fg_is_none or (not h.fg and h.name ~= "Normal") then
        fg_display = fg_display .. " (from Normal)"
      end
      if h.bg_is_none or (not h.bg and h.name ~= "Normal") then
        bg_display = bg_display .. " (from Normal)"
      end
      print(string.format("    Colors: fg=%s bg=%s", fg_display, bg_display))
      print(string.format("    Contrast Ratio: %.2f:1", result.ratio))
      print(string.format("    Bold: %s", tostring(h.bold)))
      print(string.format("    Status: %s", result.passes_aa_large and "PASS (Large text)" or "FAIL"))
    end
    print()
  end

  if #aa_large_failures > 0 then
    print(string.rep("=", 80))
    print("FAILURES - WCAG AA (Large Text, ≥3.0:1)")
    print(string.rep("=", 80))
    for _, result in ipairs(aa_large_failures) do
      local h = result.highlight
      print(string.format("\n  %s", h.name))
      print(string.format("    File: %s", h.source_file))
      print(string.format("    Colors: fg=%s bg=%s", h.fg or "(default)", h.bg or "(default)"))
      print(string.format("    Contrast Ratio: %.2f:1", result.ratio))
      print(string.format("    Bold: %s", tostring(h.bold)))
      print(string.format("    Status: FAIL"))
    end
    print()
  end

  if #aaa_normal_failures > 0 then
    print(string.rep("=", 80))
    print("FAILURES - WCAG AAA (Normal Text, ≥7.0:1)")
    print(string.rep("=", 80))
    for _, result in ipairs(aaa_normal_failures) do
      local h = result.highlight
      print(string.format("\n  %s", h.name))
      print(string.format("    File: %s", h.source_file))
      local fg_display = result.actual_fg or h.fg or "(none)"
      local bg_display = result.actual_bg or h.bg or "(none)"
      if h.fg_is_none or (not h.fg and h.name ~= "Normal") then
        fg_display = fg_display .. " (from Normal)"
      end
      if h.bg_is_none or (not h.bg and h.name ~= "Normal") then
        bg_display = bg_display .. " (from Normal)"
      end
      print(string.format("    Colors: fg=%s bg=%s", fg_display, bg_display))
      print(string.format("    Contrast Ratio: %.2f:1", result.ratio))
      print(string.format("    Bold: %s", tostring(h.bold)))
      print(string.format("    Status: %s", result.passes_aaa_large and "PASS (Large text)" or "FAIL"))
    end
    print()
  end

  if #aaa_large_failures > 0 then
    print(string.rep("=", 80))
    print("FAILURES - WCAG AAA (Large Text, ≥4.5:1)")
    print(string.rep("=", 80))
    for _, result in ipairs(aaa_large_failures) do
      local h = result.highlight
      print(string.format("\n  %s", h.name))
      print(string.format("    File: %s", h.source_file))
      print(string.format("    Colors: fg=%s bg=%s", h.fg or "(default)", h.bg or "(default)"))
      print(string.format("    Contrast Ratio: %.2f:1", result.ratio))
      print(string.format("    Bold: %s", tostring(h.bold)))
      print(string.format("    Status: FAIL"))
    end
    print()
  end

  -- Print all results in a table
  print("\n" .. string.rep("=", 80))
  print("ALL HIGHLIGHT GROUPS - DETAILED RESULTS")
  print(string.rep("=", 80))
  print(string.format("\n%-40s %-10s %-8s %-8s %-12s %s", "Highlight Group", "Ratio", "AA", "AAA", "File", "Colors"))
  print(string.rep("-", 80))

  -- Sort by name for the table
  table.sort(results, function(a, b) return a.highlight.name < b.highlight.name end)

  for _, result in ipairs(results) do
    local h = result.highlight
    local aa_status = result.passes_aa_normal and "✅" or (result.passes_aa_large and "⚠️" or "❌")
    local aaa_status = result.passes_aaa_normal and "✅" or (result.passes_aaa_large and "⚠️" or "❌")
    -- Show actual colors used for calculation (from Normal if none was specified)
    local fg_display = result.actual_fg or h.fg or "(none)"
    local bg_display = result.actual_bg or h.bg or "(none)"
    -- Mark if using Normal's colors
    if h.fg_is_none or (not h.fg and h.name ~= "Normal") then
      fg_display = fg_display .. " (Normal)"
    end
    if h.bg_is_none or (not h.bg and h.name ~= "Normal") then
      bg_display = bg_display .. " (Normal)"
    end
    local colors_str = string.format("%s / %s", fg_display, bg_display)

    print(string.format("%-40s %6.2f:1  %-8s %-8s %-12s %s", h.name, result.ratio, aa_status, aaa_status, h.source_file, colors_str))
  end

  -- Show unchecked highlights if any
  if #unchecked > 0 then
    print("\n" .. string.rep("=", 80))
    print("UNCHECKED HIGHLIGHT GROUPS (No colors defined)")
    print(string.rep("=", 80))
    print(string.format("\n%-40s %-12s %s", "Highlight Group", "File", "Colors"))
    print(string.rep("-", 80))

    table.sort(unchecked, function(a, b) return a.name < b.name end)

    for _, highlight in ipairs(unchecked) do
      local fg_display = highlight.fg or "none"
      local bg_display = highlight.bg or "none"
      local colors_str = string.format("fg=%s bg=%s", fg_display, bg_display)
      print(string.format("%-40s %-12s %s", highlight.name, highlight.source_file, colors_str))
    end
    print()
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
  local results, unchecked = checker:check_all()
  checker:print_report(results, unchecked)

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

