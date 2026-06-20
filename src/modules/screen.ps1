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
    [DllImport("user32.dll")]
    public static extern IntPtr OpenInputDesktop(uint dwFlags, bool fInherit, uint dwDesiredAccess);
    [DllImport("user32.dll")]
    public static extern bool SetThreadDesktop(IntPtr hDesktop);
    [DllImport("user32.dll")]
    public static extern bool CloseDesktop(IntPtr hDesktop);
    static bool _sw = false; static IntPtr _hd = IntPtr.Zero;
    public static void EnsureDesktop() {
        if (_sw) return;
        IntPtr h = OpenInputDesktop(0, false, 0x0002|0x0080|0x0100);
        if (h == IntPtr.Zero) h = OpenInputDesktop(0, false, 0x0002|0x0080);
        if (h != IntPtr.Zero && SetThreadDesktop(h)) { _hd = h; _sw = true; return; }
        if (h != IntPtr.Zero) CloseDesktop(h);
    }
}
'@
Add-Type -TypeDefinition $screenSig | Out-Null
[WinAPIScreen]::EnsureDesktop()

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
        [int]$Height = -1,
        [int]$Quality = 40
    )
    if (-not $OutputPath) { $OutputPath = "$PSScriptRoot\..\outputs\screenshot.jpg" }
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

    $jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
    $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]$Quality)
    $bmp.Save($OutputPath, $jpegCodec, $encoderParams)
    $bmp.Dispose()
    return $OutputPath
}

