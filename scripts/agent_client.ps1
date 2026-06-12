param(
    [string]$Action,
    [string]$Arg1,
    [string]$Arg2,
    [string]$Arg3,
    [string]$Arg4
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$OutputDir = "$scriptDir\..\outputs"
$CmdDir = "$OutputDir\commands"

if (-not (Test-Path $CmdDir)) { New-Item -ItemType Directory -Path $CmdDir -Force | Out-Null }

function Send-ToAgent {
    param([string]$Command, [int]$TimeoutMs = 10000)

    $id = [Guid]::NewGuid().ToString("N").Substring(0,8)
    $cmdFile = "$CmdDir\$id.cmd"
    $resultFile = "$CmdDir\$id.result"

    $Command | Out-File -FilePath $cmdFile -Encoding UTF8 -NoNewline

    $elapsed = 0
    $interval = 200
    while (-not (Test-Path $resultFile) -and $elapsed -lt $TimeoutMs) {
        Start-Sleep -Milliseconds $interval
        $elapsed += $interval
    }

    if (Test-Path $resultFile) {
        $result = Get-Content $resultFile -Raw -Encoding UTF8
        Remove-Item $resultFile -Force -ErrorAction SilentlyContinue
        return $result.Trim()
    }
    return "ERROR:Timeout waiting for result"
}

if (-not $Action) {
    Write-Host "Usage: agent_client.ps1 -Action <action> [-Arg1 <val> ...]"
    exit 0
}

switch ($Action) {
    "screenshot" {
        $path = $Arg1; if (-not $path) { $path = "$OutputDir\screenshot.png" }
        $resp = Send-ToAgent "SCREENSHOT|$path"
        Write-Host "SCREENSHOT: $resp"
    }
    "screensize" {
        $resp = Send-ToAgent "SCREENSIZE"
        Write-Host "SIZE: $resp"
    }
    "mousepos" {
        $resp = Send-ToAgent "MOUSEPOS"
        Write-Host "MOUSE: $resp"
    }
    "mousemove" {
        $resp = Send-ToAgent "MOUSEMOVE|$Arg1,$Arg2"
        Write-Host "MOVE: $resp"
    }
    "click" {
        $btn = $Arg1; if (-not $btn) { $btn = "left" }
        if ($Arg2 -and $Arg3) {
            $resp = Send-ToAgent "CLICK|$btn,$Arg2,$Arg3"
        } else {
            $resp = Send-ToAgent "CLICK|$btn"
        }
        Write-Host "CLICK: $resp"
    }
    "dblclick" {
        if ($Arg1 -and $Arg2) {
            $resp = Send-ToAgent "DBLCLICK|$Arg1,$Arg2"
        } else {
            $resp = Send-ToAgent "DBLCLICK|"
        }
        Write-Host "DBLCLICK: $resp"
    }
    "key" {
        $mods = if ($Arg2) { $Arg2 } else { "" }
        if ($mods) {
            $resp = Send-ToAgent "KEY|$Arg1,$mods"
        } else {
            $resp = Send-ToAgent "KEY|$Arg1"
        }
        Write-Host "KEY: $resp"
    }
    "type" {
        $resp = Send-ToAgent "TYPE|$Arg1"
        Write-Host "TYPE: $resp"
    }
    "ping" {
        $resp = Send-ToAgent "PING"
        Write-Host "PING: $resp"
    }
    default {
        Write-Host "Unknown action: $Action"
    }
}
