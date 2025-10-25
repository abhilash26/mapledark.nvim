" Maple Dark - A colorful dark theme with medium brightness and low saturation
" Inspired by: https://github.com/subframe7536/vscode-theme-maple
" License: MIT
"
" This is a compatibility shim that loads the Lua version of the theme

lua << EOF
package.loaded['mapledark'] = nil
package.loaded['mapledark.plugins'] = nil
require('mapledark').setup()
EOF
