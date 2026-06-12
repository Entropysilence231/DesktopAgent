param(
    [switch]$Help
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Load all modules
. "$scriptDir\screen.ps1"
. "$scriptDir\mouse.ps1"
. "$scriptDir\keyboard.ps1"

$OutputDir = "$scriptDir\..\outputs"

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

function Show-Help {
    Write-Host @"
=== Screen Agent Commands ===

SCREEN:
  Get-ScreenSize                          - Get primary screen dimensions
  Take-Screenshot [-Path <file>]          - Capture screen to file

MOUSE:
  Get-MousePos                            - Get current cursor position
  Move-Mouse -X <x> -Y <y>               - Move cursor
  Click-Mouse [-Button Left/Right/Middle] [-X <x> -Y <y>]
  DoubleClick-Mouse [-X <x> -Y <y>]
  Drag-Mouse -FromX -FromY -ToX -ToY

KEYBOARD:
  Send-Key -Key <key> [-Modifiers Ctrl,Alt,Shift,Win]
  Send-KeyCombo -Keys Ctrl,C
  Type-Text -Text "hello"

COMPOSITE:
  Invoke-AgentAction -Action <action>    - High-level action dispatcher
"@
}

function Invoke-AgentAction {
    param(
        [string]$Action,
        [hashtable]$Params = @{}
    )
    switch ($Action) {
        "screenshot" {
            $path = $Params["Path"]
            if (-not $path) { $path = "$OutputDir\screenshot.png" }
            $result = Take-Screenshot -OutputPath $path
            Write-Host "SCREENSHOT: $result"
        }
        "screen_size" {
            $s = Get-ScreenSize
            Write-Host "SIZE: $($s.Width)x$($s.Height)"
        }
        "mouse_pos" {
            $p = Get-MousePos
            Write-Host "MOUSE: $($p.X), $($p.Y)"
        }
        "move_mouse" {
            Move-Mouse -X $Params["X"] -Y $Params["Y"]
            Write-Host "MOVED: $($Params['X']), $($Params['Y'])"
        }
        "click" {
            Click-Mouse -Button $Params.Get_Item("Button") -X $Params.Get_Item("X") -Y $Params.Get_Item("Y")
            Write-Host "CLICKED"
        }
        "doubleclick" {
            DoubleClick-Mouse -X $Params.Get_Item("X") -Y $Params.Get_Item("Y")
            Write-Host "DOUBLE-CLICKED"
        }
        "drag" {
            Drag-Mouse -FromX $Params["FromX"] -FromY $Params["FromY"] -ToX $Params["ToX"] -ToY $Params["ToY"]
            Write-Host "DRAGGED"
        }
        "key" {
            Send-Key -Key $Params["Key"] -Modifiers $Params.Get_Item("Modifiers")
            Write-Host "KEY SENT: $($Params['Key'])"
        }
        "key_combo" {
            Send-KeyCombo -Keys $Params["Keys"]
            Write-Host "COMBO SENT"
        }
        "type" {
            Type-Text -Text $Params["Text"]
            Write-Host "TYPED"
        }
        default {
            Write-Host "Unknown action: $Action"
            Show-Help
        }
    }
}

if ($Help) { Show-Help }
