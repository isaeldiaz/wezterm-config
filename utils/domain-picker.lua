local wezterm = require('wezterm')
local Cells = require('utils.cells')

local nf = wezterm.nerdfonts
local act = wezterm.action
local attr = Cells.attr

local M = {}

---@type table<string, Cells.SegmentColors>
-- stylua: ignore
local colors = {
   attached = { fg = '#A6E3A1' },
   detached = { fg = '#6C7086' },
   label    = { fg = '#CDD6F4' },
}

local GLYPH_ATTACHED = nf.md_lan_connect --[[ '󰌘' ]]
local GLYPH_DETACHED = nf.md_lan_disconnect --[[ '󰌙' ]]

local cells = Cells:new()
   :add_segment('icon', '', colors.detached)
   :add_segment('name', '', colors.label, attr(attr.intensity('Bold')))
   :add_segment('state', '', colors.detached, attr(attr.italic()))

---Build the choice list.
---
---Unlike the launch menu this cannot be cached at config load: attachment state
---changes at runtime, and the label has to reflect what the domain is doing now.
---
---`local` is skipped -- it is always attached and detaching it would orphan every
---local pane.
local function build_choices()
   local choices = {}

   for _, domain in ipairs(wezterm.mux.all_domains()) do
      local name = domain:name()
      if name ~= 'local' then
         local attached = domain:state() == 'Attached'
         local color = attached and colors.attached or colors.detached

         cells
            :update_segment_text(
               'icon',
               ' ' .. (attached and GLYPH_ATTACHED or GLYPH_DETACHED) .. ' '
            )
            :update_segment_colors('icon', color)
            :update_segment_text('name', name)
            :update_segment_text('state', attached and '  attached' or '  detached')
            :update_segment_colors('state', color)

         table.insert(choices, {
            id = name,
            label = wezterm.format(cells:render({ 'icon', 'name', 'state' })),
         })
      end
   end

   return choices
end

---Pick a domain and flip its attachment state.
---
---Attaching is otherwise an implicit side effect of spawning into a domain, which
---is what makes a multiplexing domain re-import its whole remote tab set into
---whichever window happened to trigger it. Doing it explicitly keeps that out of
---the normal spawn path.
M.toggle = wezterm.action_callback(function(window, pane)
   window:perform_action(
      act.InputSelector({
         title = 'InputSelector: Domains',
         choices = build_choices(),
         fuzzy = true,
         fuzzy_description = GLYPH_ATTACHED .. ' Attach/detach a domain: ',
         action = wezterm.action_callback(function(inner_window, inner_pane, id)
            if not id then
               return
            end

            local domain = wezterm.mux.get_domain(id)
            if not domain then
               wezterm.log_warn('no such domain: ', id)
               return
            end

            if domain:state() == 'Attached' then
               inner_window:perform_action(act.DetachDomain({ DomainName = id }), inner_pane)
            else
               inner_window:perform_action(act.AttachDomain(id), inner_pane)
            end
         end),
      }),
      pane
   )
end)

return M
