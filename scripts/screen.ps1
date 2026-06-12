Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$screenSig = @'
using System;
using System.Runtime.InteropServices;
public class WinAPIScreen {
    [DllImport("user32.dll")]
    public static extern IntPtr GetDC(IntPtr hwnd);
    [DllImport("user32.dll")]
    public static extern int ReleaseDC(IntPtr hwnd, IntPtr hdc);
    [DllImport("gdi32.dll")]
    public static extern bool BitBlt(IntPtr hdcDest, int xDest, int yDest, int w, int h, IntPtr hdcSrc, int xSrc, int ySrc, uint rop);
}
'@
Add-Type -TypeDefinition $screenSig | Out-Null

function Get-ScreenSize {
    $screens = [System.Windows.Forms.Screen]::AllScreens
    $minX = ($screens | ForEach-Object { $_.Bounds.Left } | Measure-Object -Minimum).Minimum
    $minY = ($screens | ForEach-Object { $_.Bounds.Top } | Measure-Object -Minimum).Minimum
    $maxX = ($screens | ForEach-Object { $_.Bounds.Right } | Measure-Object -Maximum).Maximum
    $maxY = ($screens | ForEach-Object { $_.Bounds.Bottom } | Measure-Object -Maximum).Maximum
    $screen = $screens[0]
    $bounds = $screen.Bounds
    return @{
        Width  = $bounds.Width
        Height = $bounds.Height
        Left   = $bounds.Left
        Top    = $bounds.Top
        VirtualWidth  = ($maxX - $minX)
        VirtualHeight = ($maxY - $minY)
        VirtualLeft   = $minX
        VirtualTop    = $minY
    }
}

function Take-Screenshot {
    param(
        [string]$OutputPath = "",
        [int]$X = 0,
        [int]$Y = 0,
        [int]$Width = -1,
        [int]$Height = -1
    )
    if (-not $OutputPath) { $OutputPath = "$PSScriptRoot\..\outputs\screenshot.png" }
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen
    $bounds = $screen.Bounds
    if ($Width -eq -1) { $Width = $bounds.Width }
    if ($Height -eq -1) { $Height = $bounds.Height }

    $bmp = New-Object System.Drawing.Bitmap($Width, $Height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $hdcDest = $g.GetHdc()
    $hdcSrc = [WinAPIScreen]::GetDC([IntPtr]::Zero)
    [WinAPIScreen]::BitBlt($hdcDest, 0, 0, $Width, $Height, $hdcSrc, $X, $Y, 0x00CC0020) | Out-Null
    $g.ReleaseHdc($hdcDest)
    [WinAPIScreen]::ReleaseDC([IntPtr]::Zero, $hdcSrc)
    $g.Dispose()

    $dir = Split-Path $OutputPath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $bmp.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    return $OutputPath
}
