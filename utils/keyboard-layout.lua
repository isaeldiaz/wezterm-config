local wezterm = require('wezterm')
local platform = require('utils.platform')

---Keyboard layout of the focused WezTerm window.
---
---WezTerm exposes no Lua API for the active layout, so on Windows a small watcher
---process (`scripts/keyboard-layout-watcher.ps1`) is spawned once and keeps a cache
---file up to date. Reading that file is cheap enough to do on every status update.
---@class KeyboardLayout
local M = {}

---@alias KeyboardLayout.Format 'short'|'full'|'layout'

local CACHE_FILE = (os.getenv('TEMP') or wezterm.home_dir) .. '/wezterm-keyboard-layout.txt'
local WATCHER = wezterm.config_dir .. '/scripts/keyboard-layout-watcher.ps1'

---A config reload runs `setup` again in a fresh lua state, so the throttle lives in
---`wezterm.GLOBAL`, which survives reloads. The watcher itself also guards against
---duplicates, this just avoids spawning a process that would only exit again.
local SPAWN_THROTTLE_SEC = 30

---Last value read from the cache file, kept so a missing/half-written file does not
---blank out the status bar
---@type {culture: string, layout: string}|nil
local last_known = nil

---Start the layout watcher. No-op on platforms without an implementation.
M.setup = function()
   if not platform.is_win then
      return
   end

   local spawned_at = wezterm.GLOBAL.keyboard_layout_watcher_spawned_at
   if spawned_at and (os.time() - spawned_at) < SPAWN_THROTTLE_SEC then
      return
   end
   wezterm.GLOBAL.keyboard_layout_watcher_spawned_at = os.time()

   wezterm.background_child_process({
      'powershell.exe',
      '-NoLogo',
      '-NoProfile',
      '-NonInteractive',
      '-WindowStyle',
      'Hidden',
      '-ExecutionPolicy',
      'Bypass',
      '-File',
      WATCHER,
      '-OutFile',
      CACHE_FILE,
   })
end

---The current layout as a culture name (e.g. `nb-NO`) and the layout's Windows name
---(e.g. `Norwegian`)
---@return {culture: string, layout: string}|nil
M.current = function()
   local file = io.open(CACHE_FILE, 'r')
   if not file then
      return last_known
   end

   local content = file:read('*a')
   file:close()

   local culture, layout = (content or ''):match('^%s*([^\t]*)\t(.-)%s*$')
   if culture and culture ~= '' then
      last_known = { culture = culture, layout = layout }
   end

   return last_known
end

---The current layout, formatted for display
---@param format KeyboardLayout.Format `short`: `NO`, `full`: `nb-NO`, `layout`: `Norwegian`
---@return string|nil
M.get = function(format)
   local current = M.current()
   if not current then
      return nil
   end

   if format == 'full' then
      return current.culture
   end

   if format == 'layout' then
      return current.layout ~= '' and current.layout or current.culture
   end

   -- Layouts are told apart by region (`US` vs `NO`) far more often than by language,
   -- and `en-US` and `nb-NO` share neither
   local region = current.culture:match('%-(%a+)$')
   return (region or current.culture:match('^(%a+)') or current.culture):upper()
end

return M
