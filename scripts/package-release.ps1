$ErrorActionPreference = "Stop"

$projectRoot = Split-Path $PSScriptRoot -Parent
$packageJsonPath = Join-Path $projectRoot "package.json"
$releaseDir = Join-Path $projectRoot "release"
$distDir = Join-Path $projectRoot "dist\WuZiLauncher"

$package = Get-Content $packageJsonPath -Raw | ConvertFrom-Json
$version = $package.version
$zipPath = Join-Path $releaseDir ("WuZiLauncher-win-x64-v{0}.zip" -f $version)
$packageFiles = @(
  (Join-Path $distDir "WuZiLauncher.exe"),
  (Join-Path $distDir "Start-WuZi.bat"),
  (Join-Path $distDir "Stop-WuZi.bat"),
  (Join-Path $distDir "QuickStart.txt"),
  (Join-Path $distDir "QuickStart_EN.txt")
)

& (Join-Path $projectRoot "scripts\publish-launcher.ps1")

New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null
if (Test-Path $zipPath) {
  Remove-Item $zipPath -Force
}

Compress-Archive -Path $packageFiles -DestinationPath $zipPath -Force
Write-Host "Release package created: $zipPath"
