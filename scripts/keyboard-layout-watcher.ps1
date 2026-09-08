<#
.SYNOPSIS
   Publishes the keyboard layout of the focused WezTerm window to a cache file.

.DESCRIPTION
   WezTerm has no Lua API for the active keyboard layout, and shelling out on every
   status-bar update would stall the gui thread. Instead this watcher is spawned once
   (see utils/keyboard-layout.lua) and polls the Win32 layout of whichever WezTerm
   window has focus, writing "<culture>`t<layout text>" (e.g. "nb-NO`tNorwegian") to
   $OutFile on change. The status bar just reads that file.

   Exits on its own once no wezterm-gui process is left running.
#>
param(
   [Parameter(Mandatory = $true)][string] $OutFile,
   [int] $PollMs = 250
)

$ErrorActionPreference = 'Stop'

# A config reload re-spawns this script; only the first instance should survive
$created = $false
$mutex = New-Object System.Threading.Mutex($true, 'WezTermKeyboardLayoutWatcher', [ref] $created)
if (-not $created) { exit 0 }

Add-Type -Namespace WezKbd -Name Native -MemberDefinition @'
[DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
[DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
[DllImport("user32.dll")] public static extern IntPtr GetKeyboardLayout(uint idThread);
'@

$LAYOUT_KEYS = 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts'

###
 # Turn an HKL into its keyboard layout id (the 8 hex digit name of its registry key).
 #
 # The low word of an HKL is only the *language* it is filed under, which is identical
 # for every layout added to the same language (a Norwegian keyboard under English (US)
 # gives 0x04140409). The layout itself is identified by the high word:
 #   0        -> no device, fall back to the language
 #   0xFxxx   -> an alternate layout, whose low 12 bits match a "Layout Id" in the registry
 #   anything else -> the layout's own language id
 ##
function Get-LayoutId([long] $hkl) {
   $device = [int](($hkl -shr 16) -band 0xFFFF)
   $language = [int]($hkl -band 0xFFFF)

   if ($device -eq 0) {
      return '{0:x8}' -f $language
   }

   if (($device -band 0xF000) -ne 0xF000) {
      return '{0:x8}' -f $device
   }

   $layoutId = '{0:x4}' -f ($device -band 0x0FFF)
   $match = Get-ChildItem $LAYOUT_KEYS |
      Where-Object { $_.GetValue('Layout Id') -eq $layoutId } |
      Select-Object -First 1

   if ($match) { return $match.PSChildName }
   return '{0:x8}' -f $language
}

###
 # "<culture>`t<layout text>" for an HKL, e.g. "nb-NO`tNorwegian"
 ##
function Get-LayoutDescription([long] $hkl) {
   $klid = Get-LayoutId $hkl

   $culture = ''
   try {
      $langId = [Convert]::ToInt32($klid.Substring(4), 16)
      $culture = [System.Globalization.CultureInfo]::GetCultureInfo($langId).Name
   } catch { }

   $text = ''
   try { $text = (Get-ItemProperty "$LAYOUT_KEYS\$klid").'Layout Text' } catch { }

   return "$culture`t$text"
}

function Get-WezTermPids {
   return @(Get-Process -Name 'wezterm-gui' -ErrorAction SilentlyContinue |
      ForEach-Object { [uint32] $_.Id })
}

$descriptions = @{}
$last = ''
$tick = 0
$wezPids = Get-WezTermPids

while ($true) {
   if ($tick % 8 -eq 0) {
      $wezPids = Get-WezTermPids
      if ($wezPids.Count -eq 0) { break }
   }
   $tick++

   $hwnd = [WezKbd.Native]::GetForegroundWindow()
   if ($hwnd -ne [IntPtr]::Zero) {
      $procId = [uint32] 0
      $threadId = [WezKbd.Native]::GetWindowThreadProcessId($hwnd, [ref] $procId)

      # Windows keeps a layout per window, so only WezTerm's own layout is of interest
      if ($wezPids -contains $procId) {
         $hkl = [WezKbd.Native]::GetKeyboardLayout($threadId).ToInt64()

         if (-not $descriptions.ContainsKey($hkl)) {
            $descriptions[$hkl] = Get-LayoutDescription $hkl
         }
         $description = $descriptions[$hkl]

         if ($description -ne "`t" -and $description -ne $last) {
            [System.IO.File]::WriteAllText($OutFile, $description, (New-Object System.Text.UTF8Encoding $false))
            $last = $description
         }
      }
   }

   Start-Sleep -Milliseconds $PollMs
}

$mutex.ReleaseMutex()
