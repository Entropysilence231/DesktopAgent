param($Cmd, $TimeoutMs = 5000)
$id = [Guid]::NewGuid().ToString("N").Substring(0,8)
$cmdFile = "C:\Users\Administrator\Documents\桌面代理\bin\commands\$id.cmd"
$resultFile = "C:\Users\Administrator\Documents\桌面代理\bin\commands\$id.result"
$Cmd | Out-File -FilePath $cmdFile -Encoding UTF8 -NoNewline
$elapsed = 0
while (!(Test-Path $resultFile) -and $elapsed -lt $TimeoutMs) {
    Start-Sleep -Milliseconds 200
    $elapsed += 200
}
if (Test-Path $resultFile) {
    $r = Get-Content $resultFile -Raw -Encoding UTF8
    Remove-Item $resultFile -Force -ErrorAction SilentlyContinue
    return $r.Trim()
}
return "TIMEOUT"
