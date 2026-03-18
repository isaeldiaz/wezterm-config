local wezterm = require('wezterm')
local platform = require('utils.platform')

local nf = wezterm.nerdfonts

local options = {
   default_prog = {},
   launch_menu = {},
}

if platform.is_win then
   options.default_prog = { 'powershell', '-NoLogo' }
   options.launch_menu = {
      { label = 'PowerShell Core', args = { 'powershell', '-NoLogo' } },
      { label = 'PowerShell Desktop', args = { 'powershell' } },
      { label = 'Command Prompt', args = { 'cmd' } },
      { label = 'Nushell', args = { 'nu' } },
      { label = 'Msys2', args = { 'ucrt64.cmd' } },
      {
         label = 'Git Bash',
         args = { 'C:\\Users\\kevin\\scoop\\apps\\git\\current\\bin\\bash.exe' },
      },
   }

   -- Prepend configured domains so they appear in the numbered slots at the top
   local ok, local_domains = pcall(require, 'config.domains_local')
   if ok and local_domains then
      local domain_entries = {}
      for _, d in ipairs(local_domains.wsl_domains or {}) do
         local name = d.name:gsub('^[Ww][Ss][Ll]:', '')
         table.insert(domain_entries, {
            label = nf.md_ubuntu .. '  ' .. name .. ' (WSL)',
            domain = { DomainName = d.name },
         })
      end
      for _, d in ipairs(local_domains.ssh_domains or {}) do
         local icon = (d.multiplexing == 'WezTerm') and nf.md_server_network or nf.md_server
         table.insert(domain_entries, {
            label = icon .. '  ' .. d.name .. ' (' .. d.remote_address .. ')',
            domain = { DomainName = d.name },
         })
      end
      for i = #domain_entries, 1, -1 do
         table.insert(options.launch_menu, 1, domain_entries[i])
      end
   end
elseif platform.is_mac then
   options.default_prog = { '/opt/homebrew/bin/fish', '-l' }
   options.launch_menu = {
      { label = 'Bash', args = { 'bash', '-l' } },
      { label = 'Fish', args = { '/opt/homebrew/bin/fish', '-l' } },
      { label = 'Nushell', args = { '/opt/homebrew/bin/nu', '-l' } },
      { label = 'Zsh', args = { 'zsh', '-l' } },
   }
elseif platform.is_linux then
   options.default_prog = { 'fish', '-l' }
   options.launch_menu = {
      { label = 'Bash', args = { 'bash', '-l' } },
      { label = 'Fish', args = { 'fish', '-l' } },
      { label = 'Zsh', args = { 'zsh', '-l' } },
   }
end

return options
