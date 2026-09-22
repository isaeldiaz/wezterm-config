local wezterm = require('wezterm')
local platform = require('utils.platform')
local backdrops = require('utils.backdrops')
local domain_picker = require('utils.domain-picker')
local act = wezterm.action

local mod = {}

if platform.is_mac then
   mod.SUPER = 'SUPER'
   mod.SUPER_REV = 'SUPER|CTRL'
elseif platform.is_win or platform.is_linux then
   mod.SUPER = 'ALT'
   mod.SUPER_REV = 'ALT|CTRL'
end

-- stylua: ignore
local keys = {
   -- misc/useful --
   { key = 'F1', mods = 'NONE', action = 'ActivateCopyMode' },
   { key = 'F2', mods = 'NONE', action = act.ActivateCommandPalette },
   { key = 'F3', mods = 'NONE', action = act.ShowLauncher },
   { key = 'F4', mods = 'NONE', action = act.ShowLauncherArgs({ flags = 'FUZZY|TABS' }) },
   {
      key = 'F5',
      mods = 'NONE',
      action = act.ShowLauncherArgs({ flags = 'FUZZY|WORKSPACES' }),
   },
   { key = 'F11', mods = 'NONE',    action = act.ToggleFullScreen },
   { key = 'F12', mods = 'NONE',    action = act.ShowDebugOverlay },
   { key = 'f',   mods = mod.SUPER, action = act.Search({ CaseInSensitiveString = '' }) },
   {
      key = 'u',
      mods = mod.SUPER,
      action = wezterm.action.QuickSelectArgs({
         label = 'open url',
         patterns = {
            '\\((https?://\\S+)\\)',
            '\\[(https?://\\S+)\\]',
            '\\{(https?://\\S+)\\}',
            '<(https?://\\S+)>',
            '\\bhttps?://\\S+[)/a-zA-Z0-9-]+'
         },
         action = wezterm.action_callback(function(window, pane)
            local url = window:get_selection_text_for_pane(pane)
            wezterm.log_info('opening: ' .. url)
            wezterm.open_with(url)
         end),
      }),
   },

   -- cursor movement --
   { key = 'LeftArrow',  mods = mod.SUPER,     action = act.SendString '\u{1b}OH' },
   { key = 'RightArrow', mods = mod.SUPER,     action = act.SendString '\u{1b}OF' },
   { key = 'Backspace',  mods = mod.SUPER,     action = act.SendString '\u{15}' },

   -- copy/paste --
   { key = 'c',          mods = 'CTRL|SHIFT',  action = act.CopyTo('Clipboard') },
   { key = 'v',          mods = 'CTRL|SHIFT',  action = act.PasteFrom('Clipboard') },

   -- background controls (direct bindings without leader) --
   {
      key = 'b',
      mods = mod.SUPER,
      action = wezterm.action_callback(function(window, _pane)
         backdrops:toggle_focus(window)
      end)
   },

   -- LEADER-BASED BINDINGS (Win-s / Alt-s) --
   -- These mirror tmux bindings (Ctrl-s)
   
   -- tabs: spawn+close (mirrors tmux windows)
   --
   -- CurrentPaneDomain, not DefaultDomain: in a window whose panes live on a mux
   -- domain (config/domains_local.lua) spawning into the default domain mixes a
   -- local shell into a remote-backed window and drags the domain through an
   -- attach/resync on the way.
   { key = 'n',          mods = 'LEADER',     action = act.SpawnTab('CurrentPaneDomain') },
   { key = 'w',          mods = 'LEADER',     action = act.CloseCurrentTab({ confirm = false }) },

   -- windows: spawn + break a pane out (mirrors tmux new-session / break-pane)
   --
   -- There is no MoveTabToNewWindow in 20240203; PaneSelect is the equivalent and
   -- is finer-grained anyway -- pick the pane, it leaves with its own window/tab.
   { key = 'c',          mods = 'LEADER',       action = act.SpawnWindow },
   { key = '1',          mods = 'LEADER|SHIFT', action = act.PaneSelect({ mode = 'MoveToNewWindow' }) },
   { key = '2',          mods = 'LEADER|SHIFT', action = act.PaneSelect({ mode = 'MoveToNewTab' }) },

   -- panes: close (mirrors tmux kill-pane)
   { key = 'x',          mods = 'LEADER',     action = act.CloseCurrentPane({ confirm = false }) },

   -- panes: navigate + resize (WezTerm layer)
   --
   -- ALT owns the outer layer, CTRL/prefix owns the inner ones: C-hjkl is
   -- vim-tmux-navigator inside tmux/nvim, prefix+hjkl resizes tmux panes, and
   -- C-arrows resizes nvim splits. WezTerm consumes these ALT chords before
   -- they reach the wire, so the layers can never fight over a key.
   { key = 'h',          mods = mod.SUPER,     action = act.ActivatePaneDirection('Left') },
   { key = 'j',          mods = mod.SUPER,     action = act.ActivatePaneDirection('Down') },
   { key = 'k',          mods = mod.SUPER,     action = act.ActivatePaneDirection('Up') },
   { key = 'l',          mods = mod.SUPER,     action = act.ActivatePaneDirection('Right') },
   { key = 'h',          mods = mod.SUPER_REV, action = act.AdjustPaneSize({ 'Left', 2 }) },
   { key = 'j',          mods = mod.SUPER_REV, action = act.AdjustPaneSize({ 'Down', 2 }) },
   { key = 'k',          mods = mod.SUPER_REV, action = act.AdjustPaneSize({ 'Up', 2 }) },
   { key = 'l',          mods = mod.SUPER_REV, action = act.AdjustPaneSize({ 'Right', 2 }) },

   -- tabs: navigation (mirrors tmux window navigation)
   { key = 'Space',      mods = 'LEADER',     action = act.ActivateTabRelative(1) },
   { key = 'Space',      mods = 'LEADER|SHIFT', action = act.ActivateTabRelative(-1) },

   -- tabs: reorder (mirrors tmux swap-window)
   { key = ',',          mods = 'LEADER|SHIFT', action = act.MoveTabRelative(-1) },
   { key = '.',          mods = 'LEADER|SHIFT', action = act.MoveTabRelative(1) },

   -- panes: split panes (mirrors tmux splits)
   {
      key = [[\]],
      mods = 'LEADER',
      action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }),
   },
   {
      key = '-',
      mods = 'LEADER',
      action = act.SplitVertical({ domain = 'CurrentPaneDomain' }),
   },

   -- panes: zoom pane (mirrors tmux zoom)
   {
      key = 'z',
      mods = 'LEADER',
      action = act.TogglePaneZoomState,
   },

   -- panes: rearrange (mirrors tmux rotate-window / swap-pane)
   --
   -- NOTE: these only work in tabs whose panes are local to the GUI. Both
   -- actions edit the GUI client's *copy* of the split tree, so in a tab served
   -- by a mux domain (see config/domains_local.lua) the server's next layout
   -- sync reverts the content while the locally-applied sizes stick -- panes
   -- appear to change size without swapping. Upstream: wezterm#6397, #5520.
   { key = 'o',          mods = 'LEADER',       action = act.RotatePanes('Clockwise') },
   { key = 'o',          mods = 'LEADER|SHIFT', action = act.RotatePanes('CounterClockwise') },
   { key = 's',          mods = 'LEADER',       action = act.PaneSelect({ mode = 'SwapWithActive' }) },

   -- panes: resize (mirrors tmux resize) - activates key table
   {
      key = 'h',
      mods = 'LEADER',
      action = act.ActivateKeyTable({
         name = 'resize_pane',
         one_shot = false,
         timeout_milliseconds = 1000,
      }),
   },
   {
      key = 'j',
      mods = 'LEADER',
      action = act.ActivateKeyTable({
         name = 'resize_pane',
         one_shot = false,
         timeout_milliseconds = 1000,
      }),
   },
   {
      key = 'k',
      mods = 'LEADER',
      action = act.ActivateKeyTable({
         name = 'resize_pane',
         one_shot = false,
         timeout_milliseconds = 1000,
      }),
   },
   {
      key = 'l',
      mods = 'LEADER',
      action = act.ActivateKeyTable({
         name = 'resize_pane',
         one_shot = false,
         timeout_milliseconds = 1000,
      }),
   },

   -- workspaces (mirrors tmux sessions; F5 lists the existing ones)
   {
      key = 'w',
      mods = 'LEADER|SHIFT',
      action = act.PromptInputLine({
         description = wezterm.format({
            { Attribute = { Intensity = 'Bold' } },
            { Foreground = { Color = '#FAB387' } },
            { Text = 'Switch to (or create) workspace:' },
         }),
         action = wezterm.action_callback(function(window, pane, line)
            if line and line ~= '' then
               window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
            end
         end),
      }),
   },
   {
      key = 'r',
      mods = 'LEADER|SHIFT',
      action = act.PromptInputLine({
         description = wezterm.format({
            { Attribute = { Intensity = 'Bold' } },
            { Foreground = { Color = '#FAB387' } },
            { Text = 'Rename workspace to:' },
         }),
         action = wezterm.action_callback(function(window, _pane, line)
            if line and line ~= '' then
               wezterm.mux.rename_workspace(window:active_workspace(), line)
            end
         end),
      }),
   },

   -- domains: attach/detach whichever one you pick (see utils/domain-picker.lua)
   { key = 'a',          mods = 'LEADER',     action = domain_picker.toggle },

   -- reload config (mirrors tmux reload)
   { key = 'r',          mods = 'LEADER',     action = act.ReloadConfiguration },

   -- font resize mode (WezTerm-specific)
   {
      key = 'f',
      mods = 'LEADER',
      action = act.ActivateKeyTable({
         name = 'resize_font',
         one_shot = false,
         timeout_milliseconds = 8000,
      }),
   },

   -- background controls (WezTerm-specific, under leader)
   {
      key = [[/]],
      mods = 'LEADER',
      action = wezterm.action_callback(function(window, _pane)
         backdrops:random(window)
      end),
   },
   {
      key = [[,]],
      mods = 'LEADER',
      action = wezterm.action_callback(function(window, _pane)
         backdrops:cycle_back(window)
      end),
   },
   {
      key = [[.]],
      mods = 'LEADER',
      action = wezterm.action_callback(function(window, _pane)
         backdrops:cycle_forward(window)
      end),
   },
   {
      key = [[/]],
      mods = 'LEADER|SHIFT',
      action = act.InputSelector({
         title = 'InputSelector: Select Background',
         choices = backdrops:choices(),
         fuzzy = true,
         fuzzy_description = 'Select Background: ',
         action = wezterm.action_callback(function(window, _pane, idx)
            if not idx then
               return
            end
            ---@diagnostic disable-next-line: param-type-mismatch
            backdrops:set_img(window, tonumber(idx))
         end),
      }),
   },
}

-- tabs: jump straight to one by index (mirrors tmux prefix+<n>). Generated rather
-- than spelled out; LEADER-0 goes to the last tab regardless of how many there are.
for i = 1, 9 do
   table.insert(keys, { key = tostring(i), mods = 'LEADER', action = act.ActivateTab(i - 1) })
end
table.insert(keys, { key = '0', mods = 'LEADER', action = act.ActivateTab(-1) })

-- stylua: ignore
local key_tables = {
   resize_font = {
      { key = 'k',      action = act.IncreaseFontSize },
      { key = 'j',      action = act.DecreaseFontSize },
      { key = 'r',      action = act.ResetFontSize },
      { key = 'Escape', action = 'PopKeyTable' },
      { key = 'q',      action = 'PopKeyTable' },
   },
   resize_pane = {
      { key = 'k',      action = act.AdjustPaneSize({ 'Up', 1 }) },
      { key = 'j',      action = act.AdjustPaneSize({ 'Down', 1 }) },
      { key = 'h',      action = act.AdjustPaneSize({ 'Left', 1 }) },
      { key = 'l',      action = act.AdjustPaneSize({ 'Right', 1 }) },
      { key = 'Escape', action = 'PopKeyTable' },
      { key = 'q',      action = 'PopKeyTable' },
   },
}

local mouse_bindings = {
   -- Left-release copies selection to clipboard (replaces the default behaviour
   -- lost by disable_default_mouse_bindings = true). This is the primary way to
   -- copy text when not inside tmux.
   {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'NONE',
      action = act.CompleteSelection('ClipboardAndPrimarySelection'),
   },
   -- Ctrl-click opens the link under the cursor
   {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'CTRL',
      action = act.OpenLinkAtMouseCursor,
   },
}

-- On macOS, scroll events are forwarded as arrow keys when an application has
-- enabled mouse reporting (e.g. shell plugins, tmux). Explicitly bind the wheel
-- to scroll the viewport instead.
if platform.is_mac then
   table.insert(mouse_bindings, {
      event = { Down = { streak = 1, button = { WheelUp = 1 } } },
      mods = 'NONE',
      action = act.ScrollByCurrentEventWheelDelta,
   })
   table.insert(mouse_bindings, {
      event = { Down = { streak = 1, button = { WheelDown = 1 } } },
      mods = 'NONE',
      action = act.ScrollByCurrentEventWheelDelta,
   })
end

return {
   disable_default_key_bindings = true,
   disable_default_mouse_bindings = false,
   leader = { key = 's', mods = mod.SUPER },
   keys = keys,
   key_tables = key_tables,
   mouse_bindings = mouse_bindings,
}
