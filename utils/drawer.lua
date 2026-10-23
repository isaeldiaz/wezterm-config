local wezterm = require('wezterm')

local act = wezterm.action
local mux = wezterm.mux

local M = {}

-- Parked tabs stay where they are, marked and pushed to the end of the tab bar.
-- Moving them out of the window (e.g. into a hidden workspace) is not an option:
-- in 20240203 a mux client keeps a stale copy of any pane moved between windows
-- on a WezTerm-multiplexing domain, and closing that copy kills the pane.
local MAX_PARKED = 10
local STALE_DAYS = 3

-- Park time is stamped into the tab title rather than kept in wezterm.GLOBAL:
-- the title lives in the (possibly remote) mux, so it survives a GUI restart.
local MARK = '⏸ '
local STAMP_FMT = '%Y-%m-%d %H:%M'
local STAMP_PAT = '^' .. MARK .. '(%d+)%-(%d+)%-(%d+) (%d+):(%d+) ?(.*)$'

-- stylua: ignore
local colors = {
   fresh = '#A6E3A1',
   stale = '#F38BA8',
   label = '#CDD6F4',
   dim   = '#6C7086',
}

---@return number|nil parked_at, string title
local function parse_title(title)
   local y, mo, d, h, mi, rest = title:match(STAMP_PAT)
   if not y then
      return nil, title
   end
   return os.time({
      year = tonumber(y),
      month = tonumber(mo),
      day = tonumber(d),
      hour = tonumber(h),
      min = tonumber(mi),
   }),
      rest
end

---@param title string|nil a tab title, e.g. `tab.tab_title` in format-tab-title
function M.is_parked(title)
   return title ~= nil and title:match(STAMP_PAT) ~= nil
end

local function fmt_age(secs)
   if secs >= 86400 then
      return string.format('%dd', math.floor(secs / 86400))
   elseif secs >= 3600 then
      return string.format('%dh', math.floor(secs / 3600))
   end
   return string.format('%dm', math.floor(secs / 60))
end

local function toast(window, msg)
   window:toast_notification('wezterm drawer', msg, nil, 4000)
end

local function parked_entries(workspace)
   local entries = {}
   for _, w in ipairs(mux.all_windows()) do
      if w:get_workspace() == workspace then
         for _, t in ipairs(w:tabs()) do
            local parked_at, title = parse_title(t:get_title())
            if parked_at then
               local pane = t:active_pane()
               table.insert(entries, {
                  window = w,
                  tab = t,
                  parked_at = parked_at,
                  title = title,
                  label = title ~= '' and title or pane:get_title(),
                  domain = pane:get_domain_name(),
                  npanes = #t:panes(),
               })
            end
         end
      end
   end
   table.sort(entries, function(a, b)
      return a.parked_at < b.parked_at
   end)
   return entries
end

---Activate the nearest unparked tab in `delta` direction, wrapping around.
local function activate_relative(window, pane, delta)
   local tabs = window:mux_window():tabs_with_info()
   local cur = 1
   for i, t in ipairs(tabs) do
      if t.is_active then
         cur = i
      end
   end
   for step = 1, #tabs - 1 do
      local i = (cur - 1 + delta * step) % #tabs + 1
      if not M.is_parked(tabs[i].tab:get_title()) then
         window:perform_action(act.ActivateTab(i - 1), pane)
         return
      end
   end
end

M.next = wezterm.action_callback(function(window, pane)
   activate_relative(window, pane, 1)
end)

M.prev = wezterm.action_callback(function(window, pane)
   activate_relative(window, pane, -1)
end)

---Park the active tab: stamp it, move it to the end, and step off it.
M.park = wezterm.action_callback(function(window, pane)
   local tab = window:active_tab()
   if M.is_parked(tab:get_title()) then
      toast(window, 'tab is already parked')
      return
   end
   if #parked_entries(window:active_workspace()) >= MAX_PARKED then
      toast(window, 'drawer full (' .. MAX_PARKED .. '); discard something first')
      return
   end

   tab:set_title(MARK .. os.date(STAMP_FMT) .. ' ' .. tab:get_title())
   window:perform_action(act.MoveTab(#window:mux_window():tabs() - 1), pane)
   activate_relative(window, pane, 1)
end)

local function choices(entries)
   local now = os.time()
   local list = {}
   for i, e in ipairs(entries) do
      local age = now - e.parked_at
      local color = age >= STALE_DAYS * 86400 and colors.stale or colors.fresh
      table.insert(list, {
         id = tostring(i),
         label = wezterm.format({
            { Foreground = { Color = color } },
            { Text = string.format('%4s  ', fmt_age(age)) },
            { Foreground = { Color = colors.label } },
            { Attribute = { Intensity = 'Bold' } },
            { Text = e.label },
            'ResetAttributes',
            { Foreground = { Color = colors.dim } },
            { Text = '  ' .. e.domain .. (e.npanes > 1 and ('  ' .. e.npanes .. ' panes') or '') },
         }),
      })
   end
   return list
end

local function picker(window, pane, title, on_pick)
   local entries = parked_entries(window:active_workspace())
   if #entries == 0 then
      toast(window, 'drawer is empty')
      return
   end
   window:perform_action(
      act.InputSelector({
         title = title,
         choices = choices(entries),
         fuzzy = true,
         fuzzy_description = MARK .. title .. ': ',
         action = wezterm.action_callback(function(_inner_window, _inner_pane, id)
            if id then
               local e = entries[tonumber(id)]
               local gui = e.window:gui_window()
               e.tab:activate()
               if gui then
                  gui:focus()
                  on_pick(gui, e)
               end
            end
         end),
      }),
      pane
   )
end

---Pick a parked tab, clear its mark, and move it back in front of the parked ones.
M.unpark = wezterm.action_callback(function(window, pane)
   picker(window, pane, 'Unpark', function(gui, e)
      e.tab:set_title(e.title)
      local unparked = 0
      for _, t in ipairs(e.window:tabs()) do
         if t:tab_id() ~= e.tab:tab_id() and not M.is_parked(t:get_title()) then
            unparked = unparked + 1
         end
      end
      gui:perform_action(act.MoveTab(unparked), e.tab:active_pane())
   end)
end)

---Pick a parked tab and close it, killing whatever it was running.
M.discard = wezterm.action_callback(function(window, pane)
   picker(window, pane, 'Discard', function(gui, e)
      gui:perform_action(act.CloseCurrentTab({ confirm = false }), e.tab:active_pane())
   end)
end)

return M
