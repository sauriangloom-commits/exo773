param(
  [Parameter(Mandatory=$true)][string]$Exe,
  [Parameter(Mandatory=$true)][string]$OutPng,
  [string]$Scenario = "counter_drop",
  [string]$ClicksSpec = "",
  [string]$Demo = "trip"
)

# External-input smoke pass: drives the real window with OS mouse events
# (SetCursorPos + mouse_event), not the in-process probe. Coordinates are in the
# 1280x720 client layout that the probe reports and are scaled to the actual
# client size.
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class W {
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int X, int Y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, IntPtr e);
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  public struct RECT { public int Left, Top, Right, Bottom; }
  public struct POINT { public int X, Y; }
}
"@

# The game reads OS.get_cmdline_user_args(), so user arguments follow "--".
$userArgs = @("--")
if ($Demo -eq "cleave") {
  $userArgs += @("--demo-cleave", "--cleave-scenario=$Scenario")
} else {
  $userArgs += @("--demo-trip", "--trip-scenario=$Scenario")
}
$p = Start-Process -FilePath $Exe -ArgumentList $userArgs -PassThru
$deadline = (Get-Date).AddSeconds(30)
while ($p.MainWindowHandle -eq 0 -and (Get-Date) -lt $deadline) {
  Start-Sleep -Milliseconds 250
  $p.Refresh()
}
if ($p.MainWindowHandle -eq 0) {
  Write-Output "EXTERNAL FAIL no window"
  $p.Kill()
  exit 1
}
Start-Sleep -Milliseconds 1800
[W]::SetForegroundWindow($p.MainWindowHandle) | Out-Null
Start-Sleep -Milliseconds 500

$rect = New-Object W+RECT
[W]::GetClientRect($p.MainWindowHandle, [ref]$rect) | Out-Null
$origin = New-Object W+POINT
[W]::ClientToScreen($p.MainWindowHandle, [ref]$origin) | Out-Null
$w = $rect.Right - $rect.Left
$h = $rect.Bottom - $rect.Top
Write-Output ("EXTERNAL CLIENT origin=" + $origin.X + "," + $origin.Y + " size=" + $w + "x" + $h)
$sx = $w / 1280.0
$sy = $h / 720.0

$list = @()
if ($ClicksSpec.Trim() -ne "") {
  $list = $ClicksSpec.Split(";")
}
Write-Output ("EXTERNAL STEPS " + $list.Count)
foreach ($c in $list) {
  if ($c.Trim() -eq "") { continue }
  $parts = $c.Split(",")
  $x = [int]([double]$parts[0] * $sx)
  $y = [int]([double]$parts[1] * $sy)
  [W]::SetCursorPos($origin.X + $x, $origin.Y + $y) | Out-Null
  Start-Sleep -Milliseconds 180
  [W]::mouse_event(0x0002, 0, 0, 0, [IntPtr]::Zero)
  Start-Sleep -Milliseconds 70
  [W]::mouse_event(0x0004, 0, 0, 0, [IntPtr]::Zero)
  Start-Sleep -Milliseconds 550
  Write-Output ("EXTERNAL CLICK " + $parts[0] + "," + $parts[1])
}

Start-Sleep -Milliseconds 900
$bmp = New-Object System.Drawing.Bitmap($w, $h)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($origin.X, $origin.Y, 0, 0, (New-Object System.Drawing.Size($w, $h)))
$bmp.Save($OutPng, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()
Write-Output "EXTERNAL SHOT $OutPng"
$p.Kill()
