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
wezterm.on('toggle-mouse-mode', function(window, _pane)
   local overrides = window:get_config_overrides() or {}

   -- Determine current effective state: the base config has
   -- disable_default_mouse_bindings = true, so when there is no
   -- override the mouse is disabled.
   local mouse_is_disabled
   if overrides.disable_default_mouse_bindings == nil then
      mouse_is_disabled = true  -- base config default
   else
      mouse_is_disabled = overrides.disable_default_mouse_bindings
   end

   if mouse_is_disabled then
      overrides.disable_default_mouse_bindings = false
      window:toast_notification('WezTerm', 'Mouse Mode: ENABLED', nil, 2000)
   else
      overrides.disable_default_mouse_bindings = true
      window:toast_notification('WezTerm', 'Mouse Mode: DISABLED', nil, 2000)
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
