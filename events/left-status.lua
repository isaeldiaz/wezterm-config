local wezterm = require('wezterm')
local Cells = require('utils.cells')

local nf = wezterm.nerdfonts
local attr = Cells.attr

local M = {}

local GLYPH_SEMI_CIRCLE_LEFT  = nf.ple_left_half_circle_thick  --[[ '' ]]
local GLYPH_SEMI_CIRCLE_RIGHT = nf.ple_right_half_circle_thick --[[ '' ]]
local GLYPH_KEY_TABLE         = nf.md_table_key                --[[ '󱏅' ]]
local GLYPH_KEY               = nf.md_key                      --[[ '󰌆' ]]
local GLYPH_ZOOM              = nf.md_arrow_expand_all or nf.fa_expand or '⊞'
local GLYPH_WORKSPACE         = nf.md_view_dashboard             --[[ '󰕮' ]]
local GLYPH_WINDOW            = nf.md_dock_window                --[[ '󰕰' ]]

---@type table<string, Cells.SegmentColors>
local colors = {
   default = { bg = '#fab387', fg = '#1c1b19' },
   scircle = { bg = 'rgba(0, 0, 0, 0.4)', fg = '#fab387' },
   zoom    = { bg = '#a6e3a1', fg = '#1c1b19' },
   zoom_sc = { bg = 'rgba(0, 0, 0, 0.4)', fg = '#a6e3a1' },
   ws      = { bg = '#89b4fa', fg = '#1c1b19' },
   ws_sc   = { bg = 'rgba(0, 0, 0, 0.4)', fg = '#89b4fa' },
}

local cells = Cells:new()
local zoom_cells = Cells:new()
local ws_cells = Cells:new()

cells
   :add_segment(1, GLYPH_SEMI_CIRCLE_LEFT, colors.scircle, attr(attr.intensity('Bold')))
   :add_segment(2, ' ', colors.default, attr(attr.intensity('Bold')))
   :add_segment(3, ' ', colors.default, attr(attr.intensity('Bold')))
   :add_segment(4, GLYPH_SEMI_CIRCLE_RIGHT, colors.scircle, attr(attr.intensity('Bold')))

zoom_cells
   :add_segment(1, GLYPH_SEMI_CIRCLE_LEFT, colors.zoom_sc, attr(attr.intensity('Bold')))
   :add_segment(2, ' ' .. GLYPH_ZOOM .. ' ZOOM ', colors.zoom, attr(attr.intensity('Bold')))
   :add_segment(3, GLYPH_SEMI_CIRCLE_RIGHT, colors.zoom_sc, attr(attr.intensity('Bold')))

ws_cells
   :add_segment(1, GLYPH_SEMI_CIRCLE_LEFT, colors.ws_sc, attr(attr.intensity('Bold')))
   :add_segment(2, '', colors.ws, attr(attr.intensity('Bold')))
   :add_segment(3, GLYPH_SEMI_CIRCLE_RIGHT, colors.ws_sc, attr(attr.intensity('Bold')))

local function is_pane_zoomed(window, pane)
   local tab = window:mux_window():active_tab()
   if not tab then return false end
   local pane_id = pane:pane_id()
   for _, info in ipairs(tab:panes_with_info()) do
      if info.pane:pane_id() == pane_id then
         return info.is_zoomed
      end
   end
   return false
end

---Append `items` to `res`, separated by a space if `res` already has content.
local function append(res, items)
   if #res > 0 then
      table.insert(res, { Text = ' ' })
   end
   for _, item in ipairs(items) do
      table.insert(res, item)
   end
end

M.setup = function()
   wezterm.on('update-right-status', function(window, pane)
      local res = {}

      -- Workspace name + mux window id. With several windows open side by side and
      -- different work in each, they are otherwise indistinguishable.
      ws_cells:update_segment_text(
         2,
         (' %s %s  %s %d '):format(
            GLYPH_WORKSPACE,
            window:active_workspace(),
            GLYPH_WINDOW,
            window:window_id()
         )
      )
      append(res, ws_cells:render_all())

      -- Leader wins over the key table: it is the more transient of the two.
      local name = window:active_key_table()
      local indicator = nil

      if name then
         cells
            :update_segment_text(2, GLYPH_KEY_TABLE)
            :update_segment_text(3, ' ' .. string.upper(name))
         indicator = cells:render_all()
      end

      if window:leader_is_active() then
         cells:update_segment_text(2, GLYPH_KEY):update_segment_text(3, ' ')
         indicator = cells:render_all()
      end

      if indicator then
         append(res, indicator)
      end

      if is_pane_zoomed(window, pane) then
         append(res, zoom_cells:render_all())
      end

      window:set_left_status(wezterm.format(res))
   end)
end

return M
