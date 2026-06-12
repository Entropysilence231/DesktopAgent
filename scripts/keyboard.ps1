Add-Type -AssemblyName System.Windows.Forms

$keySig = @'
using System;
using System.Runtime.InteropServices;
public class WinAPIKey {
    [DllImport("user32.dll")]
    public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
    [DllImport("user32.dll")]
    public static extern short VkKeyScan(char ch);
}
'@
Add-Type -TypeDefinition $keySig | Out-Null

$KEYEVENTF_KEYDOWN = 0x0000
$KEYEVENTF_KEYUP   = 0x0002

function Send-Key {
    param(
        [string]$Key,
        [string[]]$Modifiers = @(),
        [int]$DelayMs = 50
    )
    $modMap = @{
        "Ctrl"  = 0x11; "Alt"   = 0x12; "Shift" = 0x10; "Win" = 0x5B
    }
    $keyMap = @{
        "Enter" = 0x0D; "Tab" = 0x09; "Escape" = 0x1B; "Esc" = 0x1B
        "Space" = 0x20; "Backspace" = 0x08; "Delete" = 0x2E; "Insert" = 0x2D
        "Home" = 0x24; "End" = 0x23; "PageUp" = 0x21; "PageDown" = 0x22
        "Up" = 0x26; "Down" = 0x28; "Left" = 0x25; "Right" = 0x27
        "F1" = 0x70; "F2" = 0x71; "F3" = 0x72; "F4" = 0x73; "F5" = 0x74; "F6" = 0x75
        "F7" = 0x76; "F8" = 0x77; "F9" = 0x78; "F10" = 0x79; "F11" = 0x7A; "F12" = 0x7B
        "PrintScreen" = 0x2C
    }

    foreach ($mod in $Modifiers) {
        if ($modMap.ContainsKey($mod)) {
            [WinAPIKey]::keybd_event($modMap[$mod], 0, $KEYEVENTF_KEYDOWN, [UIntPtr]::Zero)
        }
    }

    $vk = 0
    if ($Key.Length -eq 1) {
        $vk = [WinAPIKey]::VkKeyScan($Key[0]) -band 0xFF
    } elseif ($keyMap.ContainsKey($Key)) {
        $vk = $keyMap[$Key]
    } else {
        Write-Host "[Send-Key] Unknown key: $Key"
    }

    [WinAPIKey]::keybd_event($vk, 0, $KEYEVENTF_KEYDOWN, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds $DelayMs
    [WinAPIKey]::keybd_event($vk, 0, $KEYEVENTF_KEYUP, [UIntPtr]::Zero)

    foreach ($mod in $Modifiers) {
        if ($modMap.ContainsKey($mod)) {
            [WinAPIKey]::keybd_event($modMap[$mod], 0, $KEYEVENTF_KEYUP, [UIntPtr]::Zero)
        }
    }
}

function Send-KeyCombo {
    param(
        [string[]]$Keys,
        [int]$DelayMs = 50
    )
    $modKeys = @("Ctrl", "Alt", "Shift", "Win")
    $modifiers = $Keys | Where-Object { $_ -in $modKeys }
    $mainKey = $Keys | Where-Object { $_ -notin $modKeys } | Select-Object -Last 1
    if (-not $mainKey) { $mainKey = $Keys[-1]; $modifiers = $Keys[0..($Keys.Count - 2)] }
    Send-Key -Key $mainKey -Modifiers $modifiers -DelayMs $DelayMs
}

function Type-Text {
    param(
        [string]$Text,
        [int]$DelayMs = 30
    )
    foreach ($ch in $Text.ToCharArray()) {
        $str = [string]$ch
        if ($str -eq "`r") { continue }
        if ($str -eq "`n") {
            Send-Key -Key "Enter" -DelayMs $DelayMs
            continue
        }
        [System.Windows.Forms.SendKeys]::SendWait($str)
        Start-Sleep -Milliseconds $DelayMs
    }
}
