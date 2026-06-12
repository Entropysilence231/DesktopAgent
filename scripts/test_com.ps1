Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$outFile = $Args[0]
$result = @{}

# Test cursor
try {
    $pos = [System.Windows.Forms.Cursor]::Position
    $result.CursorX = $pos.X
    $result.CursorY = $pos.Y
} catch {
    $result.CursorError = $_.Exception.Message
}

# Test screenshot
try {
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen
    $bmp = New-Object System.Drawing.Bitmap(100, 100)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen(0, 0, 0, 0, $bmp.Size)
    $g.Dispose()
    $bmp.Dispose()
    $result.ScreenshotOK = $true
} catch {
    $result.ScreenshotOK = $false
    $result.ScreenshotError = $_.Exception.Message
}

$result | ConvertTo-Json | Out-File -FilePath $outFile -Encoding UTF8
