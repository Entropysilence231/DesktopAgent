Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Write-Host "=== Testing .NET Forms control ==="

# Test mouse position read
$pos = [System.Windows.Forms.Cursor]::Position
Write-Host "Cursor position: $($pos.X), $($pos.Y)"

# Test mouse move
try {
    $oldPos = [System.Windows.Forms.Cursor]::Position
    $testX = $oldPos.X + 10
    $testY = $oldPos.Y + 10
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($testX, $testY)
    Start-Sleep -Milliseconds 200
    $newPos = [System.Windows.Forms.Cursor]::Position
    Write-Host "After move: $($newPos.X), $($newPos.Y)"
    # Restore
    [System.Windows.Forms.Cursor]::Position = $oldPos
    Write-Host "Mouse move: OK"
} catch {
    Write-Host "Mouse move failed: $_"
}

# Test SendKeys
try {
    [System.Windows.Forms.SendKeys]::SendWait("")
    Write-Host "SendKeys init: OK"
} catch {
    Write-Host "SendKeys failed: $_"
}

# Test screen info
$screen = [System.Windows.Forms.Screen]::PrimaryScreen
Write-Host "Screen: $($screen.Bounds.Width)x$($screen.Bounds.Height)"
