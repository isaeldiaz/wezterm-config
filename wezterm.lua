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

-- Helper to detect if the pane is likely running inside tmux.
-- Checks both local process name and the pane title, which typically
-- reflects the remote process when connected via SSH+tmux.
local function is_tmux_pane(pane)
   local process_name = pane:get_foreground_process_name() or ''
   if process_name:find('tmux') then
      return true
   end
   local title = pane:get_title() or ''
   if title:find('tmux') then
      return true
   end
   -- If connected via SSH, tmux is on the remote side and won't show
   -- as the local foreground process. Check if the pane's domain is
   -- an SSH domain as a hint that tmux commands should be forwarded.
   local domain = pane:get_domain_name() or ''
   if domain ~= 'local' and domain ~= '' and not domain:find('^wsl:') then
      return true
   end
   return false
end

-- Mouse toggle event handler
wezterm.on('toggle-mouse-mode', function(window, pane)
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
      -- Currently disabled -> enable
      overrides.disable_default_mouse_bindings = false
      window:toast_notification('WezTerm', 'Mouse Mode: ENABLED', nil, 2000)

      if is_tmux_pane(pane) then
         pane:send_text('tmux set -g mouse on\r')
      end
   else
      -- Currently enabled -> disable
      overrides.disable_default_mouse_bindings = true
      window:toast_notification('WezTerm', 'Mouse Mode: DISABLED', nil, 2000)

      if is_tmux_pane(pane) then
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
