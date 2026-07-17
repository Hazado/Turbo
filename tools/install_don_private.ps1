# Private install of DoN BiS changes into a local MacroQuest tree.
# Does NOT push to public / TurboPatcher. Run from anywhere:
#   powershell -File tools\install_don_private.ps1 [-MqRoot "D:\path\to\MacroQuest"]

param(
    [string]$MqRoot = "D:\E3NextAndMQNextBinary-main"
)

$ErrorActionPreference = "Stop"
$src = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
# Script lives in Turbo repo tools/; src is repo root
$src = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

if (-not (Test-Path $MqRoot)) {
    throw "MQ root not found: $MqRoot"
}

$files = @(
    "lua\turbogear\catalogs\lazbis.lua",
    "lua\turbogear\bis_catalog.lua",
    "lua\turbogear\bis.lua",
    "lua\turbogear\spell_snapshot.lua",
    "lua\turbogear\tabs\bis.lua",
    "lua\turbogear\config.lua",
    "lua\turbogear\CHANGELOG",
    "lua\Turbo\rulepacks\BiS_announce_list.ini"
)

foreach ($f in $files) {
    $from = Join-Path $src $f
    $to = Join-Path $MqRoot $f
    $dir = Split-Path $to -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Copy-Item -Path $from -Destination $to -Force
    Write-Host "copied $f"
}

foreach ($cfgName in @("config", "Config")) {
    $cfg = Join-Path $MqRoot $cfgName
    if (-not (Test-Path $cfg)) { continue }
    Get-ChildItem -Path $cfg -Filter "TurboGear_dcat_*.lua" -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-Item $_.FullName -Force
        Write-Host "removed $($_.FullName)"
    }
}

Write-Host ""
Write-Host "Private install done. Restart TurboGear (/lua run turbogear) and open BiS -> DoN."
Write-Host "Do NOT git push public or cut a release until in-game smoke passes."
