# Performance Optimizations

## Overview

Maple Dark includes several performance optimizations to ensure fast startup times and minimal memory overhead.

## Caching Mechanisms

### 1. Color Palette Caching

The color palette is computed only once and cached for subsequent accesses:

```lua
-- First access - computes colors
local c = require('mapledark').colors
print(c.blue) -- Computes and caches

-- Subsequent accesses - uses cache
print(c.red)  -- From cache (instant)
```

**Benefit**: Eliminates repeated color table creation

### 2. Highlight Group Caching

The theme tracks whether highlights have been loaded:

```lua
-- First load - applies all highlights
require('mapledark').setup()

-- Subsequent calls - skips if already loaded
require('mapledark').setup() -- Returns immediately

-- Force reload if needed
require('mapledark').setup({ force = true })
```

**Benefit**: Prevents redundant highlight API calls

### 3. Lazy Plugin Loading

Plugin highlights are loaded asynchronously after the main theme:

```lua
-- Core highlights load immediately (synchronous)
-- Plugin highlights load in next event loop (asynchronous)
```

**Benefit**: Faster initial colorscheme activation

### 4. Modular Plugin Support

Load only the plugin highlights you actually use:

```lua
require('mapledark').setup({
  plugins = { 'lazy', 'mason', 'fzflua' } -- Only these plugins
})
```

**Benefit**: Reduces number of highlight groups to process

### 5. On-Demand Loading

Load plugin highlights only when the plugin is actually used:

```lua
-- Load telescope highlights only when opening telescope
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'TelescopePrompt',
  once = true,
  callback = function()
    require('mapledark').load_plugin('telescope')
  end,
})
```

**Benefit**: Minimal startup time impact for unused plugins

## Performance Comparison

### Before Optimizations
- Initial load: ~5-8ms
- Reload: ~5-8ms (redundant work)
- All plugins loaded upfront

### After Optimizations
- Initial load: ~3-5ms (core only)
- Plugin load: ~2-3ms (async, after startup)
- Reload (cached): <0.1ms
- Selective loading: ~0.5-1ms per plugin

## Memory Efficiency

### Read-Only Color Table

The colors table is protected from accidental modifications:

```lua
local c = require('mapledark').colors
c.blue = '#000000' -- Error: Colors table is read-only
```

**Benefit**: Prevents cache corruption and ensures consistency

### Shared Color References

All plugin loaders receive the same cached color table:

```lua
-- Same color reference used everywhere
local c1 = require('mapledark').colors
local c2 = require('mapledark').colors
-- c1 and c2 point to the same cached table
```

**Benefit**: Minimal memory overhead

## Best Practices

### For Users

1. **Minimal Config**: Use default settings for best out-of-box performance
   ```lua
   vim.cmd.colorscheme('mapledark')
   ```

2. **Selective Loading**: If you have many plugins, load only what you use
   ```lua
   require('mapledark').setup({
     plugins = { 'lazy', 'mason', 'telescope' }
   })
   ```

3. **Lazy Loading**: For rarely used plugins, load on-demand
   ```lua
   -- Load oil.nvim highlights only when opening oil
   vim.api.nvim_create_autocmd('FileType', {
     pattern = 'oil',
     once = true,
     callback = function()
       require('mapledark').load_plugin('oil')
     end,
   })
   ```

### For Theme Developers

1. **Use Reload**: When developing, use reload to clear cache
   ```lua
   require('mapledark').reload()
   ```

2. **Profile Performance**: Time your changes
   ```lua
   vim.cmd('profile start profile.log')
   vim.cmd('profile func require("mapledark").setup')
   require('mapledark').reload()
   vim.cmd('profile stop')
   ```

## Benchmarking

To benchmark the theme on your system:

```lua
-- Measure cold start
local start = vim.loop.hrtime()
require('mapledark').setup()
local duration = (vim.loop.hrtime() - start) / 1e6
print(string.format('Cold start: %.2fms', duration))

-- Measure cached reload
start = vim.loop.hrtime()
require('mapledark').setup()
duration = (vim.loop.hrtime() - start) / 1e6
print(string.format('Cached reload: %.2fms', duration))

-- Measure forced reload
start = vim.loop.hrtime()
require('mapledark').setup({ force = true })
duration = (vim.loop.hrtime() - start) / 1e6
print(string.format('Forced reload: %.2fms', duration))
```

## Technical Details

### Cache Structure

```lua
_cache = {
  colors = nil,              -- Color palette (lazy-initialized)
  highlights_loaded = false, -- Core highlights flag
  plugins_loaded = {},       -- Per-plugin tracking
}
```

### Metatable for Colors

The colors table uses a metatable for lazy initialization and protection:

```lua
M.colors = setmetatable({}, {
  __index = function(_, key)
    return get_colors()[key] -- Lazy load on first access
  end,
  __newindex = function()
    error("Colors table is read-only", 2) -- Prevent modifications
  end,
})
```

## Future Optimizations

Potential areas for further improvement:

1. **Highlight Batching**: Group similar highlights for batch API calls
2. **Compile-Time Colors**: Pre-compute color values at build time
3. **Incremental Updates**: Only update changed highlights
4. **Config Validation**: Early validation to prevent redundant work

## Conclusion

These optimizations ensure Maple Dark remains fast and efficient regardless of how many plugins you use or how often you reload your config.

