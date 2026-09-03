local wezterm = require('wezterm')
local platform = require('utils.platform')

local nf = wezterm.nerdfonts

---Return the first path in `candidates` that exists, or nil.
local function find_executable(candidates)
   for _, path in ipairs(candidates) do
      local f = io.open(path, 'r')
      if f then
         f:close()
         return path
      end
   end
end

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
         args = {
            find_executable({
               (os.getenv('USERPROFILE') or '')
                  .. '\\scoop\\apps\\git\\current\\bin\\bash.exe',
               'C:\\Program Files\\Git\\bin\\bash.exe',
               'C:\\Program Files (x86)\\Git\\bin\\bash.exe',
            }) or 'bash.exe',
         },
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
         local icon = (d.multiplexing == 'WezTerm') and nf.dev_arduino or nf.fa_microchip
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
   local zsh = find_executable({ '/bin/zsh', '/usr/bin/zsh', '/usr/local/bin/zsh', '/opt/homebrew/bin/zsh' })
   options.default_prog = zsh and { zsh, '-l' } or { 'bash', '-l' }
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
