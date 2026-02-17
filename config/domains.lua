local platform = require('utils.platform')

local options = {
   -- ref: https://wezfurlong.org/wezterm/config/lua/SshDomain.html
   ssh_domains = {},

   -- ref: https://wezfurlong.org/wezterm/multiplexing.html#unix-domains
   unix_domains = {},

   -- ref: https://wezfurlong.org/wezterm/config/lua/WslDomain.html
   wsl_domains = {},
}

if platform.is_win then
   options.ssh_domains = {
      {
         name = 'USERvm',
         remote_address = 'USERvm.dyn.int.example.com',
         username = 'USER',
         multiplexing = 'None',
      },
      {
         name = 'naboo',
         remote_address = 'remote-host-2',
         username = 'USER',
         multiplexing = 'None',
      },
   }

   options.wsl_domains = {
      {
         name = 'wsl:ubuntu-bash',
         distribution = 'Ubuntu-24.04',
         username = 'USER',
         default_cwd = '/home/USER',
         default_prog = { 'bash', '-l' },
      },
   }
end

return options
