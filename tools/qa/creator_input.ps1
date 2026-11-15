param(
  [Parameter(Mandatory=$true)][string]$Exe,
  [Parameter(Mandatory=$true)][string]$OutPng,
  # Semicolon-separated steps. "C:x,y" is a click; "W:delta" is a mouse wheel
  # scroll; "K:TEXT:foo", "K:TAB", "K:ENTER", "K:DOWN" and "K:ESC" are
  # keystrokes. Coordinates are in the 1280x720 client layout and are scaled to
  # the actual client size.
  [string]$Steps = "",
  [string]$GameArgs = "--demo-creator",
  [int]$DelayMs = 700
)

# External-input pass for the campaign creator: drives the real window with OS
# mouse and keyboard events, not the in-process probes.
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

$userArgs = @()
if ($GameArgs.Trim() -ne "") {
  $userArgs = @("--") + $GameArgs.Split(" ")
}
if ($userArgs.Count -gt 0) {
  $p = Start-Process -FilePath $Exe -ArgumentList $userArgs -PassThru
} else {
  $p = Start-Process -FilePath $Exe -PassThru
}
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
$wshell = New-Object -ComObject WScript.Shell

function Invoke-Click([double]$cx, [double]$cy) {
  $x = [int]($cx * $sx)
  $y = [int]($cy * $sy)
  [W]::SetCursorPos($origin.X + $x, $origin.Y + $y) | Out-Null
  Start-Sleep -Milliseconds 180
  [W]::mouse_event(0x0002, 0, 0, 0, [IntPtr]::Zero)
  Start-Sleep -Milliseconds 70
  [W]::mouse_event(0x0004, 0, 0, 0, [IntPtr]::Zero)
  Start-Sleep -Milliseconds $DelayMs
  Write-Output ("EXTERNAL CLICK " + $cx + "," + $cy)
}

foreach ($s in $Steps.Split(";")) {
  if ($s.Trim() -eq "") { continue }
  if ($s.StartsWith("C:")) {
    $parts = $s.Substring(2).Split(",")
    Invoke-Click ([double]$parts[0]) ([double]$parts[1])
  } elseif ($s.StartsWith("W:")) {
    [W]::SetCursorPos($origin.X + [int]($w / 2), $origin.Y + [int]($h / 2)) | Out-Null
    Start-Sleep -Milliseconds 120
    $delta = [int]$s.Substring(2)
    [W]::mouse_event(0x0800, 0, 0, [BitConverter]::ToUInt32([BitConverter]::GetBytes($delta), 0), [IntPtr]::Zero)
    Start-Sleep -Milliseconds 400
    Write-Output ("EXTERNAL WHEEL " + $s.Substring(2))
  } elseif ($s.StartsWith("K:")) {
    $k = $s.Substring(2)
    if ($k.StartsWith("TEXT:")) {
      $wshell.SendKeys($k.Substring(5))
    } elseif ($k -eq "TAB") {
      $wshell.SendKeys("{TAB}")
    } elseif ($k -eq "ENTER") {
      $wshell.SendKeys("{ENTER}")
    } elseif ($k -eq "DOWN") {
      $wshell.SendKeys("{DOWN}")
    } elseif ($k -eq "ESC") {
      $wshell.SendKeys("{ESC}")
    }
    Start-Sleep -Milliseconds 400
    Write-Output ("EXTERNAL KEY " + $k)
  }
}

[W]::SetForegroundWindow($p.MainWindowHandle) | Out-Null
Start-Sleep -Milliseconds 300
$bmp = New-Object System.Drawing.Bitmap($w, $h)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($origin.X, $origin.Y, 0, 0, (New-Object System.Drawing.Size($w, $h)))
$bmp.Save($OutPng, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()
Write-Output "EXTERNAL SHOT $OutPng"
$p.Kill()
