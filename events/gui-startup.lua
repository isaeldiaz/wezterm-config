local wezterm = require('wezterm')
local mux = wezterm.mux

local M = {}

M.setup = function()
   wezterm.on('gui-startup', function(cmd)
      local _, _, window = mux.spawn_window(cmd or {})

      -- gui_window() is not guaranteed to be resolvable this early; unguarded it
      -- raises and aborts the handler, which drops the maximize entirely.
      local gui = window:gui_window()
      if gui then
         gui:maximize()
      end
   end)
end

return M
