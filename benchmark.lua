-- Benchmark script for Maple Dark theme performance
-- Run with: nvim -u benchmark.lua

local M = {}

-- Measure execution time
local function measure(name, fn)
  local start = vim.loop.hrtime()
  fn()
  local duration = (vim.loop.hrtime() - start) / 1e6
  return duration
end

-- Run benchmark
function M.run()
  print('===========================================')
  print('  Maple Dark Performance Benchmark')
  print('===========================================\n')

  -- Test 1: Cold start
  package.loaded['mapledark'] = nil
  package.loaded['mapledark.plugins'] = nil
  local cold_start = measure('Cold start', function()
    require('mapledark').setup()
  end)
  print(string.format('✓ Cold start:           %.2f ms', cold_start))

  -- Test 2: Cached reload (should be very fast)
  local cached_reload = measure('Cached reload', function()
    require('mapledark').setup()
  end)
  print(string.format('✓ Cached reload:        %.2f ms (%.1fx faster)', cached_reload, cold_start / cached_reload))

  -- Test 3: Forced reload
  local forced_reload = measure('Forced reload', function()
    require('mapledark').setup({ force = true })
  end)
  print(string.format('✓ Forced reload:        %.2f ms', forced_reload))

  -- Test 4: Clear cache
  local clear_cache = measure('Clear cache', function()
    require('mapledark').clear_cache()
  end)
  print(string.format('✓ Clear cache:          %.2f ms', clear_cache))

  -- Test 5: Plugin loading (lazy)
  require('mapledark').clear_cache()
  require('mapledark').setup()
  local plugin_load = measure('Single plugin load', function()
    require('mapledark').load_plugin('lazy')
  end)
  print(string.format('✓ Single plugin load:   %.2f ms', plugin_load))

  -- Test 6: Selective plugin loading
  require('mapledark').clear_cache()
  package.loaded['mapledark'] = nil
  package.loaded['mapledark.plugins'] = nil
  local selective = measure('Selective (3 plugins)', function()
    require('mapledark').setup({
      plugins = { 'lazy', 'mason', 'telescope' }
    })
  end)
  print(string.format('✓ Selective loading:    %.2f ms', selective))

  -- Test 7: Color access
  local color_access = measure('Color table access', function()
    local colors = require('mapledark').colors
    for i = 1, 1000 do
      local _ = colors.blue
      local _ = colors.red
      local _ = colors.green
    end
  end)
  print(string.format('✓ 3000 color accesses:  %.2f ms', color_access))

  -- Test 8: Memory usage
  local before = collectgarbage('count')
  require('mapledark').clear_cache()
  package.loaded['mapledark'] = nil
  package.loaded['mapledark.plugins'] = nil
  require('mapledark').setup()
  collectgarbage('collect')
  local after = collectgarbage('count')
  local memory = after - before
  print(string.format('✓ Memory footprint:     %.2f KB', memory))

  print('\n===========================================')
  print('  Benchmark Complete')
  print('===========================================\n')

  -- Performance summary
  print('Performance Summary:')
  print(string.format('  • Cache effectiveness: %.1fx speedup', cold_start / cached_reload))
  print(string.format('  • Plugin load overhead: %.1f%%', (plugin_load / cold_start) * 100))
  print(string.format('  • Selective loading saves: %.1f ms', cold_start - selective))
  print(string.format('  • Memory per theme: ~%.0f KB', memory))

  -- Recommendations
  print('\nRecommendations:')
  if cold_start < 5 then
    print('  ✓ Excellent: Theme loads very quickly!')
  elseif cold_start < 10 then
    print('  ✓ Good: Theme loads reasonably fast')
  else
    print('  ⚠ Consider: Use selective plugin loading')
  end

  if cached_reload > 1 then
    print('  ⚠ Cache may not be working properly')
  else
    print('  ✓ Cache working perfectly')
  end

  print('\n')
end

-- Auto-run if executed directly
if vim.fn.argc() == 0 then
  -- Set up minimal config
  vim.opt.runtimepath:append(vim.fn.getcwd())
  vim.opt.termguicolors = true

  -- Run benchmark after a short delay to ensure everything is loaded
  vim.defer_fn(function()
    M.run()

    -- Exit after showing results
    print('Press ENTER to exit...')
    vim.fn.getchar()
    vim.cmd('quit!')
  end, 100)
end

return M

