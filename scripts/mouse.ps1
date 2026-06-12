Add-Type -AssemblyName System.Windows.Forms

$mouseSig = @'
using System;
using System.Runtime.InteropServices;
public class WinAPIMouse {
    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")]
    public static extern bool GetCursorPos(out POINT lpPoint);
    [DllImport("user32.dll")]
    public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, UIntPtr dwExtraInfo);
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);
}
[StructLayout(LayoutKind.Sequential)]
public struct POINT {
    public int X;
    public int Y;
}
'@
Add-Type -TypeDefinition $mouseSig | Out-Null

$MOUSEEVENTF_LEFTDOWN   = 0x0002
$MOUSEEVENTF_LEFTUP     = 0x0004
$MOUSEEVENTF_RIGHTDOWN  = 0x0008
$MOUSEEVENTF_RIGHTUP    = 0x0010
$MOUSEEVENTF_MIDDLEDOWN = 0x0020
$MOUSEEVENTF_MIDDLEUP   = 0x0040

function Get-MousePos {
    $point = New-Object POINT
    [WinAPIMouse]::GetCursorPos([ref]$point) | Out-Null
    return @{ X = $point.X; Y = $point.Y }
}

function Move-Mouse {
    param([int]$X, [int]$Y)
    [WinAPIMouse]::SetCursorPos($X, $Y)
}

function Click-Mouse {
    param(
        [string]$Button = "Left",
        [int]$X = -1,
        [int]$Y = -1,
        [int]$DelayMs = 50
    )
    if ($X -ge 0 -and $Y -ge 0) {
        Move-Mouse -X $X -Y $Y
        Start-Sleep -Milliseconds $DelayMs
    }
    switch ($Button) {
        "Left" {
            [WinAPIMouse]::mouse_event($MOUSEEVENTF_LEFTDOWN, 0, 0, 0, [UIntPtr]::Zero)
            Start-Sleep -Milliseconds $DelayMs
            [WinAPIMouse]::mouse_event($MOUSEEVENTF_LEFTUP, 0, 0, 0, [UIntPtr]::Zero)
        }
        "Right" {
            [WinAPIMouse]::mouse_event($MOUSEEVENTF_RIGHTDOWN, 0, 0, 0, [UIntPtr]::Zero)
            Start-Sleep -Milliseconds $DelayMs
            [WinAPIMouse]::mouse_event($MOUSEEVENTF_RIGHTUP, 0, 0, 0, [UIntPtr]::Zero)
        }
        "Middle" {
            [WinAPIMouse]::mouse_event($MOUSEEVENTF_MIDDLEDOWN, 0, 0, 0, [UIntPtr]::Zero)
            Start-Sleep -Milliseconds $DelayMs
            [WinAPIMouse]::mouse_event($MOUSEEVENTF_MIDDLEUP, 0, 0, 0, [UIntPtr]::Zero)
        }
    }
}

function DoubleClick-Mouse {
    param(
        [int]$X = -1,
        [int]$Y = -1,
        [int]$DelayMs = 50
    )
    if ($X -ge 0 -and $Y -ge 0) {
        Move-Mouse -X $X -Y $Y
        Start-Sleep -Milliseconds $DelayMs
    }
    [WinAPIMouse]::mouse_event($MOUSEEVENTF_LEFTDOWN, 0, 0, 0, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds $DelayMs
    [WinAPIMouse]::mouse_event($MOUSEEVENTF_LEFTUP, 0, 0, 0, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds ($DelayMs * 2)
    [WinAPIMouse]::mouse_event($MOUSEEVENTF_LEFTDOWN, 0, 0, 0, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds $DelayMs
    [WinAPIMouse]::mouse_event($MOUSEEVENTF_LEFTUP, 0, 0, 0, [UIntPtr]::Zero)
}

function Drag-Mouse {
    param(
        [int]$FromX,
        [int]$FromY,
        [int]$ToX,
        [int]$ToY,
        [int]$Steps = 20,
        [int]$DelayMs = 10
    )
    Move-Mouse -X $FromX -Y $FromY
    Start-Sleep -Milliseconds 50
    [WinAPIMouse]::mouse_event($MOUSEEVENTF_LEFTDOWN, 0, 0, 0, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds 30
    for ($i = 1; $i -le $Steps; $i++) {
        $cx = [int]($FromX + ($ToX - $FromX) * $i / $Steps)
        $cy = [int]($FromY + ($ToY - $FromY) * $i / $Steps)
        Move-Mouse -X $cx -Y $cy
        Start-Sleep -Milliseconds $DelayMs
    }
    [WinAPIMouse]::mouse_event($MOUSEEVENTF_LEFTUP, 0, 0, 0, [UIntPtr]::Zero)
}
