------------------------------------------------------------------------------------------
-- Inspired by https://github.com/wez/wezterm/discussions/628#discussioncomment-1874614 --
------------------------------------------------------------------------------------------

local wezterm = require('wezterm')
local Cells = require('utils.cells')
local OptsValidator = require('utils.opts-validator')

---
-- =======================================
-- Defining event setup options and schema
-- =======================================

---@alias Event.TabTitleOptions { unseen_icon: 'circle' | 'numbered_circle' | 'numbered_box', hide_active_tab_unseen: boolean }

---Setup options for the tab title
local EVENT_OPTS = {}

---@type OptsSchema
EVENT_OPTS.schema = {
   {
      name = 'unseen_icon',
      type = 'string',
      enum = { 'circle', 'numbered_circle', 'numbered_box' },
      default = 'circle',
   },
   {
      name = 'hide_active_tab_unseen',
      type = 'boolean',
      default = true,
   },
}
EVENT_OPTS.validator = OptsValidator:new(EVENT_OPTS.schema)

---
-- ===================
-- Constants and icons
-- ===================

local nf = wezterm.nerdfonts

local M = {}

local GLYPH_SCIRCLE_LEFT = nf.ple_left_half_circle_thick --[[  ]]
local GLYPH_SCIRCLE_RIGHT = nf.ple_right_half_circle_thick --[[  ]]
local GLYPH_CIRCLE = nf.fa_circle --[[  ]]
local GLYPH_ADMIN = nf.md_shield_half_full --[[ 󰞀 ]]
local GLYPH_LINUX = nf.cod_terminal_linux --[[  ]]
local GLYPH_DEBUG = nf.fa_bug --[[  ]]
-- local GLYPH_SEARCH = nf.fa_search --[[  ]]
local GLYPH_SEARCH = '🔭'

local GLYPH_UNSEEN_NUMBERED_BOX = {
   [1] = nf.md_numeric_1_box_multiple, --[[ 󰼏 ]]
   [2] = nf.md_numeric_2_box_multiple, --[[ 󰼐 ]]
   [3] = nf.md_numeric_3_box_multiple, --[[ 󰼑 ]]
   [4] = nf.md_numeric_4_box_multiple, --[[ 󰼒 ]]
   [5] = nf.md_numeric_5_box_multiple, --[[ 󰼓 ]]
   [6] = nf.md_numeric_6_box_multiple, --[[ 󰼔 ]]
   [7] = nf.md_numeric_7_box_multiple, --[[ 󰼕 ]]
   [8] = nf.md_numeric_8_box_multiple, --[[ 󰼖 ]]
   [9] = nf.md_numeric_9_box_multiple, --[[ 󰼗 ]]
   [10] = nf.md_numeric_9_plus_box_multiple, --[[ 󰼘 ]]
}

local GLYPH_UNSEEN_NUMBERED_CIRCLE = {
   [1] = nf.md_numeric_1_circle, --[[ 󰲠 ]]
   [2] = nf.md_numeric_2_circle, --[[ 󰲢 ]]
   [3] = nf.md_numeric_3_circle, --[[ 󰲤 ]]
   [4] = nf.md_numeric_4_circle, --[[ 󰲦 ]]
   [5] = nf.md_numeric_5_circle, --[[ 󰲨 ]]
   [6] = nf.md_numeric_6_circle, --[[ 󰲪 ]]
   [7] = nf.md_numeric_7_circle, --[[ 󰲬 ]]
   [8] = nf.md_numeric_8_circle, --[[ 󰲮 ]]
   [9] = nf.md_numeric_9_circle, --[[ 󰲰 ]]
   [10] = nf.md_numeric_9_plus_circle, --[[ 󰲲 ]]
}

local TITLE_INSET = {
   DEFAULT = 6,
   ICON = 8,
}

local RENDER_VARIANTS = {
   { 'scircle_left', 'title', 'padding', 'scircle_right' },
   { 'scircle_left', 'title', 'unseen_output', 'padding', 'scircle_right' },
   { 'scircle_left', 'admin', 'title', 'padding', 'scircle_right' },
   { 'scircle_left', 'admin', 'title', 'unseen_output', 'padding', 'scircle_right' },
   { 'scircle_left', 'wsl', 'title', 'padding', 'scircle_right' },
   { 'scircle_left', 'wsl', 'title', 'unseen_output', 'padding', 'scircle_right' },
}

-- Unique icon per domain — add new entries here when new domains are configured
-- stylua: ignore
local DOMAIN_ICONS = {
   ['local']       = nf.md_microsoft_windows, -- 󰖳  Windows local
   ['local-mux']   = nf.md_microsoft_windows, -- 󰖳
   ['idiazvm-mux'] = nf.dev_arduino,          --   SSH + WezTerm mux
   ['naboo']       = nf.fa_microchip,         --   SSH plain
}

-- Shell process names: when one of these is the foreground proc, show CWD instead
local SHELL_NAMES = {
   powershell = true, pwsh = true, bash = true,
   nu = true, zsh = true, fish = true, cmd = true,
}

local function get_domain_icon(domain)
   if DOMAIN_ICONS[domain] then return DOMAIN_ICONS[domain] end
   if domain:match('^WSL:') then return nf.dev_ubuntu end
   return nf.fa_microchip -- fallback for unknown SSH domains
end

local function shorten_cwd(path, max_len)
   if not path or path == '' then return '' end
   path = path:gsub('\\', '/')
   path = path:gsub('^/mnt/%a/[Uu]sers/[^/]+', '~')  -- WSL Windows mounts
   path = path:gsub('^%a:[/\\][Uu]sers/[^/]+', '~')  -- Windows native paths
   path = path:gsub('^/home/[^/]+', '~')              -- Linux/SSH home
   if #path > max_len then
      local parts = {}
      for p in path:gmatch('[^/]+') do table.insert(parts, p) end
      if #parts >= 2 then
         path = parts[#parts - 1] .. '/' .. parts[#parts]
      elseif #parts == 1 then
         path = parts[1]
      end
   end
   if #path > max_len then
      path = path:sub(1, max_len - 1) .. '…'
   end
   return path
end

---@type table<string, Cells.SegmentColors>
-- stylua: ignore
local colors = {
   text_default          = { bg = '#45475A', fg = '#1C1B19' },
   text_hover            = { bg = '#5D87A3', fg = '#1C1B19' },
   text_active           = { bg = '#74c7ec', fg = '#11111B' },

   unseen_output_default = { bg = '#45475A', fg = '#FFA066' },
   unseen_output_hover   = { bg = '#5D87A3', fg = '#FFA066' },
   unseen_output_active  = { bg = '#74c7ec', fg = '#FFA066' },

   scircle_default       = { bg = 'rgba(0, 0, 0, 0.4)', fg = '#45475A' },
   scircle_hover         = { bg = 'rgba(0, 0, 0, 0.4)', fg = '#5D87A3' },
   scircle_active        = { bg = 'rgba(0, 0, 0, 0.4)', fg = '#74C7EC' },
}

---
-- ================
-- Helper functions
-- ================

---@param proc string
local function clean_process_name(proc)
   local a = string.gsub(proc, '(.*[/\\])(.*)', '%2')
   return a:gsub('%.exe$', '')
end

---@param process_name string
---@param base_title string
---@param max_width number
---@param inset number
local function create_title(process_name, base_title, max_width, inset)
   local title

   if process_name:len() > 0 then
      title = process_name .. ' ~ ' .. base_title
   else
      title = base_title
   end

   if base_title == 'Debug' then
      title = GLYPH_DEBUG .. ' DEBUG'
      inset = inset - 2
   end

   if base_title:match('^InputSelector:') ~= nil then
      title = base_title:gsub('InputSelector:', GLYPH_SEARCH)
      inset = inset - 2
   end

   if title:len() > max_width - inset then
      local diff = title:len() - max_width + inset
      title = title:sub(1, title:len() - diff)
   else
      local padding = max_width - title:len() - inset
      title = title .. string.rep(' ', padding)
   end

   return title
end

---@param panes any[] WezTerm https://wezfurlong.org/wezterm/config/lua/pane/index.html
local function check_unseen_output(panes)
   local unseen_output = false
   local unseen_output_count = 0

   for i = 1, #panes, 1 do
      if panes[i].has_unseen_output then
         unseen_output = true
         if unseen_output_count >= 10 then
            unseen_output_count = 10
            break
         end
         unseen_output_count = unseen_output_count + 1
      end
   end

   return unseen_output, unseen_output_count
end

---
-- =================
-- Tab class and API
-- =================

---@class Tab
---@field title string
---@field cells FormatCells
---@field title_locked boolean
---@field locked_title string
---@field is_wsl boolean
---@field is_admin boolean
---@field unseen_output boolean
---@field unseen_output_count number
---@field is_active boolean
local Tab = {}
Tab.__index = Tab

function Tab:new()
   local tab = {
      title = '',
      cells = Cells:new(),
      title_locked = false,
      locked_title = '',
      is_wsl = false,
      is_admin = false,
      unseen_output = false,
      unseen_output_count = 0,
   }
   return setmetatable(tab, self)
end

---@param event_opts Event.TabTitleOptions
---@param tab any WezTerm https://wezfurlong.org/wezterm/config/lua/MuxTab/index.html
---@param max_width number
function Tab:set_info(event_opts, tab, max_width)
   local process_name = clean_process_name(tab.active_pane.foreground_process_name)

   self.is_wsl = process_name:match('^wsl') ~= nil
   self.is_admin = (
      tab.active_pane.title:match('^Administrator: ') or tab.active_pane.title:match('(Admin)')
   ) ~= nil
   self.unseen_output = false
   self.unseen_output_count = 0

   if not event_opts.hide_active_tab_unseen or not tab.is_active then
      self.unseen_output, self.unseen_output_count = check_unseen_output(tab.panes)
   end

   local inset = (self.is_admin or self.is_wsl) and TITLE_INSET.ICON or TITLE_INSET.DEFAULT
   if self.unseen_output then
      inset = inset + 2
   end

   if self.title_locked then
      self.title = create_title('', self.locked_title, max_width, inset)
      return
   end
   self.title = create_title(process_name, tab.active_pane.title, max_width, inset)
end

function Tab:create_cells()
   local attr = self.cells.attr
   self.cells
      :add_segment('scircle_left', GLYPH_SCIRCLE_LEFT)
      :add_segment('admin', ' ' .. GLYPH_ADMIN)
      :add_segment('wsl', ' ' .. GLYPH_LINUX)
      :add_segment('title', ' ', nil, attr(attr.intensity('Bold')))
      :add_segment('unseen_output', ' ' .. GLYPH_CIRCLE)
      :add_segment('padding', ' ')
      :add_segment('scircle_right', GLYPH_SCIRCLE_RIGHT)
end

---@param title string
function Tab:update_and_lock_title(title)
   self.locked_title = title
   self.title_locked = true
end

---@param event_opts Event.TabTitleOptions
---@param is_active boolean
---@param hover boolean
function Tab:update_cells(event_opts, is_active, hover)
   local tab_state = 'default'
   if is_active then
      tab_state = 'active'
   elseif hover then
      tab_state = 'hover'
   end

   self.cells:update_segment_text('title', ' ' .. self.title)

   if event_opts.unseen_icon == 'numbered_box' and self.unseen_output then
      self.cells:update_segment_text(
         'unseen_output',
         ' ' .. GLYPH_UNSEEN_NUMBERED_BOX[self.unseen_output_count]
      )
   end
   if event_opts.unseen_icon == 'numbered_circle' and self.unseen_output then
      self.cells:update_segment_text(
         'unseen_output',
         ' ' .. GLYPH_UNSEEN_NUMBERED_CIRCLE[self.unseen_output_count]
      )
   end

   self.cells
      :update_segment_colors('scircle_left', colors['scircle_' .. tab_state])
      :update_segment_colors('admin', colors['text_' .. tab_state])
      :update_segment_colors('wsl', colors['text_' .. tab_state])
      :update_segment_colors('title', colors['text_' .. tab_state])
      :update_segment_colors('unseen_output', colors['unseen_output_' .. tab_state])
      :update_segment_colors('padding', colors['text_' .. tab_state])
      :update_segment_colors('scircle_right', colors['scircle_' .. tab_state])
end

---@return FormatItem[] (ref: https://wezfurlong.org/wezterm/config/lua/wezterm/format.html)
function Tab:render()
   local variant_idx = self.is_admin and 3 or 1
   if self.is_wsl then
      variant_idx = 5
   end

   if self.unseen_output then
      variant_idx = variant_idx + 1
   end
   return self.cells:render(RENDER_VARIANTS[variant_idx])
end

---@type Tab[]
local tab_list = {}

---@param opts? Event.TabTitleOptions Default: {unseen_icon = 'circle', hide_active_tab_unseen = true}
M.setup = function(opts)
   local valid_opts, err = EVENT_OPTS.validator:validate(opts or {})

   if err then
      wezterm.log_error(err)
   end

   -- CUSTOM EVENT
   -- Event listener to manually update the tab name
   -- Tab name will remain locked until the `reset-tab-title` is triggered
   wezterm.on('tabs.manual-update-tab-title', function(window, pane)
      window:perform_action(
         wezterm.action.PromptInputLine({
            description = wezterm.format({
               { Foreground = { Color = '#FFFFFF' } },
               { Attribute = { Intensity = 'Bold' } },
               { Text = 'Enter new name for tab' },
            }),
            action = wezterm.action_callback(function(_window, _pane, line)
               if line ~= nil then
                  local tab = window:active_tab()
                  local id = tab:tab_id()
                  tab_list[id]:update_and_lock_title(line)
               end
            end),
         }),
         pane
      )
   end)

   -- CUSTOM EVENT
   -- Event listener to unlock manually set tab name
   wezterm.on('tabs.reset-tab-title', function(window, _pane)
      local tab = window:active_tab()
      local id = tab:tab_id()
      tab_list[id].title_locked = false
   end)

   -- CUSTOM EVENT
   -- Event listener to manually update the tab name
   wezterm.on('tabs.toggle-tab-bar', function(window, _pane)
      local effective_config = window:effective_config()
      window:set_config_overrides({
         enable_tab_bar = not effective_config.enable_tab_bar,
         background = effective_config.background,
      })
   end)

   -- BUILTIN EVENT
   -- Tab title: unique domain icon + smart title (process name or CWD)
   wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
      local pane = tab.active_pane
      local icon = get_domain_icon(pane.domain_name)

      local proc = clean_process_name(pane.foreground_process_name)
      local title
      if proc == '' or SHELL_NAMES[proc:lower()] then
         local cwd_url = pane.current_working_dir
         if cwd_url then
            local raw = cwd_url.file_path or tostring(cwd_url):gsub('^file://[^/]*', '')
            title = shorten_cwd(raw, max_width - 6)
         end
         title = (title and title ~= '') and title or (proc ~= '' and proc or pane.domain_name)
      else
         title = proc
      end

      local bg   = tab.is_active and '#74c7ec' or (hover and '#5D87A3' or '#45475A')
      local fg   = tab.is_active and '#11111B' or '#1C1B19'
      local edge = 'rgba(0, 0, 0, 0.4)'

      -- For plain SSH domains (multiplexing='None'), foreground_process_name
      -- returns the local ssh client, not the remote process — use unseen output
      -- as a proxy. Same fallback when the mux doesn't populate the field.
      local has_running_proc
      if proc == '' or proc == 'ssh' then
         has_running_proc = tab.active_pane.has_unseen_output
      else
         has_running_proc = not SHELL_NAMES[proc:lower()]
      end
      local show_indicator   = not tab.is_active and has_running_proc

      local cells = {
         { Background = { Color = edge } },
         { Foreground = { Color = bg   } },
         { Text = GLYPH_SCIRCLE_LEFT },
         { Background = { Color = bg   } },
         { Foreground = { Color = fg   } },
         { Attribute = { Intensity = 'Bold' } },
         { Text = ' ' .. icon .. ' ' .. title },
      }

      if show_indicator then
         table.insert(cells, { Foreground = { Color = '#FFA066' } })
         table.insert(cells, { Text = ' ' .. nf.md_circle_small })
      end

      table.insert(cells, { Foreground = { Color = fg   } })
      table.insert(cells, { Text = ' ' })
      table.insert(cells, { Background = { Color = edge } })
      table.insert(cells, { Foreground = { Color = bg   } })
      table.insert(cells, { Text = GLYPH_SCIRCLE_RIGHT })

      return cells
   end)

   -- BUILTIN EVENT
   -- Window title: active process + CWD, with domain when not local
   wezterm.on('format-window-title', function(tab, pane, tabs, panes, config)
      local proc = clean_process_name(pane.foreground_process_name)
      local domain = pane.domain_name
      local cwd = ''
      if pane.current_working_dir then
         local raw = pane.current_working_dir.file_path
            or tostring(pane.current_working_dir):gsub('^file://[^/]*', '')
         cwd = shorten_cwd(raw, 50)
      end

      local title
      if proc == '' or SHELL_NAMES[proc:lower()] then
         title = cwd ~= '' and cwd or proc
      else
         title = cwd ~= '' and (proc .. '  ' .. cwd) or proc
      end

      if domain ~= 'local' and domain ~= 'local-mux' then
         title = title .. '  [' .. domain .. ']'
      end

      return title
   end)

end

return M
