param(
    [string]$OutputPath = "$PSScriptRoot\..\bin\DesktopAgent.exe"
)
$srcFile = "$PSScriptRoot\..\src\DesktopAgent.cs"
if (-not (Test-Path $srcFile)) {
    Write-Error "Source file not found: $srcFile"
    exit 1
}
$references = @(
    "System.Windows.Forms.dll",
    "System.Drawing.dll"
)
$refArgs = ($references | ForEach-Object { "-reference:$_" }) -join " "
Write-Host "Compiling DesktopAgent.cs -> $OutputPath ..."
$csc = Get-Command "csc" -ErrorAction SilentlyContinue
if ($csc) {
    $cmd = "csc /target:exe /out:`"$OutputPath`" $refArgs `"$srcFile`""
    Invoke-Expression $cmd
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Compiled successfully: $OutputPath"
    } else {
        Write-Error "Compilation failed with exit code $LASTEXITCODE"
    }
    exit $LASTEXITCODE
}
Write-Host "No C# compiler found. Install .NET Framework SDK or Mono."
exit 1
