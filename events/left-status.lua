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

---@type table<string, Cells.SegmentColors>
local colors = {
   default = { bg = '#fab387', fg = '#1c1b19' },
   scircle = { bg = 'rgba(0, 0, 0, 0.4)', fg = '#fab387' },
   zoom    = { bg = '#a6e3a1', fg = '#1c1b19' },
   zoom_sc = { bg = 'rgba(0, 0, 0, 0.4)', fg = '#a6e3a1' },
}

local zoom_panes = {}

local cells = Cells:new()
local zoom_cells = Cells:new()

cells
   :add_segment(1, GLYPH_SEMI_CIRCLE_LEFT, colors.scircle, attr(attr.intensity('Bold')))
   :add_segment(2, ' ', colors.default, attr(attr.intensity('Bold')))
   :add_segment(3, ' ', colors.default, attr(attr.intensity('Bold')))
   :add_segment(4, GLYPH_SEMI_CIRCLE_RIGHT, colors.scircle, attr(attr.intensity('Bold')))

zoom_cells
   :add_segment(1, GLYPH_SEMI_CIRCLE_LEFT, colors.zoom_sc, attr(attr.intensity('Bold')))
   :add_segment(2, ' ' .. GLYPH_ZOOM .. ' ZOOM ', colors.zoom, attr(attr.intensity('Bold')))
   :add_segment(3, GLYPH_SEMI_CIRCLE_RIGHT, colors.zoom_sc, attr(attr.intensity('Bold')))

M.setup = function()
   wezterm.on('zoom.toggled', function(_window, pane)
      local id = pane:pane_id()
      zoom_panes[id] = not zoom_panes[id] or nil
   end)

   wezterm.on('update-right-status', function(window, pane)
      local name = window:active_key_table()
      local res = {}

      if name then
         cells
            :update_segment_text(2, GLYPH_KEY_TABLE)
            :update_segment_text(3, ' ' .. string.upper(name))
         res = cells:render_all()
      end

      if window:leader_is_active() then
         cells:update_segment_text(2, GLYPH_KEY):update_segment_text(3, ' ')
         res = cells:render_all()
      end

      if zoom_panes[pane:pane_id()] then
         if #res > 0 then
            table.insert(res, { Text = ' ' })
         end
         for _, item in ipairs(zoom_cells:render_all()) do
            table.insert(res, item)
         end
      end

      window:set_left_status(wezterm.format(res))
   end)
end

return M
