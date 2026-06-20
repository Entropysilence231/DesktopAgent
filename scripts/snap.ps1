Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$s = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$b = New-Object System.Drawing.Bitmap $s.Width, $s.Height
$g = [System.Drawing.Graphics]::FromImage($b)
$g.CopyFromScreen(0, 0, 0, 0, $b.Size)
$g.Dispose()
$c = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
$p = New-Object System.Drawing.Imaging.EncoderParameters(1)
$p.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]40)
$b.Save($Args[0], $c, $p)
$b.Dispose()
