local wezterm = require('wezterm')
local Config = require('config')

require('utils.backdrops')
   -- :set_focus('#000000')
   -- :set_images_dir(require('wezterm').home_dir .. '/Pictures/Wallpapers/')
   :set_images()
   :random()

require('events.left-status').setup()
require('events.right-status').setup({ date_format = '%a %H:%M:%S' })
require('events.tab-title').setup({ hide_active_tab_unseen = false, unseen_icon = 'numbered_box' })
require('events.new-tab-button').setup()
require('events.gui-startup').setup()

-- Mouse toggle event handler
wezterm.on('toggle-mouse-mode', function(window, pane)
   local overrides = window:get_config_overrides() or {}

   -- Toggle state
   if overrides.disable_default_mouse_bindings then
      overrides.disable_default_mouse_bindings = false
      window:toast_notification('WezTerm', 'Mouse Mode: ENABLED', nil, 2000)

      -- Enable tmux mouse if in tmux
      local process_name = pane:get_foreground_process_name()
      if process_name and process_name:find('tmux') then
         pane:send_text('tmux set -g mouse on\r')
      end
   else
      overrides.disable_default_mouse_bindings = true
      window:toast_notification('WezTerm', 'Mouse Mode: DISABLED', nil, 2000)

      -- Disable tmux mouse if in tmux
      local process_name = pane:get_foreground_process_name()
      if process_name and process_name:find('tmux') then
         pane:send_text('tmux set -g mouse off\r')
      end
   end

   window:set_config_overrides(overrides)
end)

return Config:init()
   :append(require('config.appearance'))
   :append(require('config.bindings'))
   :append(require('config.domains'))
   :append(require('config.fonts'))
   :append(require('config.general'))
   :append(require('config.launch')).options
