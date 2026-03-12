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
   -- Load local domain overrides (not tracked in git, see config/domains_local.lua)
   local ok, local_domains = pcall(require, 'config.domains_local')
   if ok then
      if local_domains.ssh_domains then options.ssh_domains = local_domains.ssh_domains end
      if local_domains.wsl_domains then options.wsl_domains = local_domains.wsl_domains end
      if local_domains.unix_domains then options.unix_domains = local_domains.unix_domains end
   end
end

return options
