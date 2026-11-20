param(
    [Parameter(Mandatory = $true)][string]$Exe,
    [string]$GameArgs = "-- --demo",
    [Parameter(Mandatory = $true)][string]$Out,
    [Parameter(Mandatory = $true)][string]$Script
)

# Drives the running game with OS-level input (user32 keybd_event/mouse_event)
# and captures the client area, so a check exercises the same path as a player
# rather than calling into the game.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Native {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr after, int x, int y, int cx, int cy, uint flags);
    [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr hWnd, out RECT r);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr hWnd, ref POINT p);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
    [DllImport("user32.dll")] public static extern uint MapVirtualKey(uint code, uint type);
    [DllImport("user32.dll")] public static extern void mouse_event(uint flags, int dx, int dy, int data, UIntPtr extra);
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
}
"@
[Native]::SetProcessDPIAware() | Out-Null

$keys = @{
    'w' = 0x57; 'a' = 0x41; 's' = 0x53; 'd' = 0x44; 'q' = 0x51; 'e' = 0x45
    'f' = 0x46; 'j' = 0x4A; 'c' = 0x43; 'i' = 0x49; 'l' = 0x4C; 'p' = 0x50
    'tab' = 0x09; 'escape' = 0x1B; 'enter' = 0x0D; 'space' = 0x20
    'left' = 0x25; 'up' = 0x26; 'right' = 0x27; 'down' = 0x28
    'pageup' = 0x21; 'pagedown' = 0x22
}

if (-not (Test-Path $Out)) { New-Item -ItemType Directory -Path $Out | Out-Null }

$proc = Start-Process -FilePath $Exe -ArgumentList $GameArgs -PassThru
$handle = [IntPtr]::Zero
for ($i = 0; $i -lt 80; $i++) {
    Start-Sleep -Milliseconds 250
    $proc.Refresh()
    if ($proc.HasExited) { throw "the game exited before its window appeared" }
    if ($proc.MainWindowHandle -ne [IntPtr]::Zero) { $handle = $proc.MainWindowHandle; break }
}
if ($handle -eq [IntPtr]::Zero) { throw "no main window handle appeared" }

$rect = New-Object Native+RECT
[Native]::GetClientRect($handle, [ref]$rect) | Out-Null
$origin = New-Object Native+POINT
[Native]::ClientToScreen($handle, [ref]$origin) | Out-Null
$width = $rect.Right - $rect.Left
$height = $rect.Bottom - $rect.Top
Write-Output "WINDOW pid=$($proc.Id) client=${width}x${height} origin=$($origin.X),$($origin.Y)"

# The chat window and other apps may cover the game, and a foreground call from
# a background process is often refused, so raise it to topmost first.
function Focus-Game() {
    [Native]::ShowWindow($handle, 9) | Out-Null
    # Topmost only: moving or resizing would invalidate the cached client origin.
    [Native]::SetWindowPos($handle, [IntPtr](-1), 0, 0, 0, 0, 0x0043) | Out-Null
    [Native]::BringWindowToTop($handle) | Out-Null
    [Native]::SetForegroundWindow($handle) | Out-Null
    Start-Sleep -Milliseconds 300
    if ([Native]::GetForegroundWindow() -ne $handle) {
        try { [Microsoft.VisualBasic.Interaction]::AppActivate($proc.Id) | Out-Null } catch { }
        Start-Sleep -Milliseconds 250
    }
    return ([Native]::GetForegroundWindow() -eq $handle)
}

Write-Output "FOREGROUND activated=$(Focus-Game)"

function Save-Shot([string]$name) {
    $bmp = New-Object System.Drawing.Bitmap($width, $height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($origin.X, $origin.Y, 0, 0, $bmp.Size)
    $path = Join-Path $Out "$name.png"
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    Write-Output "SHOT $name $path"
}

function Send-Key([string]$name, [int]$count) {
    if ($name -eq 'shifttab') {
        if ([Native]::GetForegroundWindow() -ne $handle) { Focus-Game | Out-Null }
        for ($i = 0; $i -lt $count; $i++) {
            [Native]::keybd_event(0xA0, [byte]([Native]::MapVirtualKey(0xA0, 0)), 0, [UIntPtr]::Zero)
            Start-Sleep -Milliseconds 60
            [Native]::keybd_event(0x09, [byte]([Native]::MapVirtualKey(0x09, 0)), 0, [UIntPtr]::Zero)
            Start-Sleep -Milliseconds 60
            [Native]::keybd_event(0x09, [byte]([Native]::MapVirtualKey(0x09, 0)), 2, [UIntPtr]::Zero)
            Start-Sleep -Milliseconds 60
            [Native]::keybd_event(0xA0, [byte]([Native]::MapVirtualKey(0xA0, 0)), 2, [UIntPtr]::Zero)
            Start-Sleep -Milliseconds 240
        }
        Write-Output "KEY shifttab x$count"
        return
    }
    if (-not $keys.ContainsKey($name)) { throw "unknown key '$name'" }
    if ([Native]::GetForegroundWindow() -ne $handle) { Focus-Game | Out-Null }
    $vk = [byte]$keys[$name]
    # Godot matches actions on the physical key, which needs the scan code; a
    # zero scan code only reaches GUI focus traversal (Tab) and not game actions.
    $scan = [byte]([Native]::MapVirtualKey([uint32]$vk, 0))
    for ($i = 0; $i -lt $count; $i++) {
        [Native]::keybd_event($vk, $scan, 0, [UIntPtr]::Zero)
        Start-Sleep -Milliseconds 60
        [Native]::keybd_event($vk, $scan, 2, [UIntPtr]::Zero)
        Start-Sleep -Milliseconds 240
    }
    Write-Output "KEY $name x$count"
}

function Send-Wheel([int]$x, [int]$y, [int]$delta) {
    if ([Native]::GetForegroundWindow() -ne $handle) { Focus-Game | Out-Null }
    [Native]::SetCursorPos($origin.X + $x, $origin.Y + $y) | Out-Null
    Start-Sleep -Milliseconds 250
    [Native]::mouse_event(0x0800, 0, 0, $delta, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds 500
    Write-Output "WHEEL $x,$y delta=$delta"
}

function Send-Click([int]$x, [int]$y) {
    if ([Native]::GetForegroundWindow() -ne $handle) { Focus-Game | Out-Null }
    [Native]::SetCursorPos($origin.X + $x, $origin.Y + $y) | Out-Null
    Start-Sleep -Milliseconds 250
    [Native]::mouse_event(0x0002, 0, 0, 0, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds 80
    [Native]::mouse_event(0x0004, 0, 0, 0, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds 600
    Write-Output "CLICK $x,$y"
}

try {
    foreach ($raw in $Script.Split(';')) {
        $step = $raw.Trim()
        if ($step -eq '') { continue }
        $parts = $step.Split(':')
        switch ($parts[0]) {
            'wait' { Start-Sleep -Milliseconds ([int]$parts[1]) }
            'fg' { Write-Output "FG match=$([Native]::GetForegroundWindow() -eq $handle)" }
            'shot' { Save-Shot $parts[1] }
            'key' {
                $count = 1
                if ($parts.Count -gt 2) { $count = [int]$parts[2] }
                Send-Key $parts[1] $count
            }
            'wheel' { Send-Wheel ([int]$parts[1]) ([int]$parts[2]) ([int]$parts[3]) }
            'click' { Send-Click ([int]$parts[1]) ([int]$parts[2]) }
            default { throw "unknown step '$step'" }
        }
    }
}
finally {
    if (-not $proc.HasExited) { Stop-Process -Id $proc.Id -Force }
    Write-Output "DONE pid=$($proc.Id)"
}
