$ErrorActionPreference = "Stop"

$projectRoot = Split-Path $PSScriptRoot -Parent
$outputDir = Join-Path $projectRoot "dist\WuZiLauncher-macos"
$appBundleDir = Join-Path $outputDir "WuZiLauncher.app"
$appContentsDir = Join-Path $appBundleDir "Contents"
$appMacOsDir = Join-Path $appContentsDir "MacOS"
$appResourcesDir = Join-Path $appContentsDir "Resources\app"
$appResourceRootDir = Join-Path $appContentsDir "Resources"
$releaseDir = Join-Path $projectRoot "release"
$packageJsonPath = Join-Path $projectRoot "package.json"
$package = Get-Content $packageJsonPath -Raw | ConvertFrom-Json
$version = $package.version
$zipPath = Join-Path $releaseDir ("WuZiLauncher-macos-v{0}.zip" -f $version)
$tarGzPath = Join-Path $releaseDir ("WuZiLauncher-macos-v{0}.tar.gz" -f $version)
$pythonPackager = Join-Path $projectRoot "scripts\package-macos-tar.py"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Write-LfFile {
  param(
    [string]$Path,
    [string]$Content
  )

  $normalized = $Content -replace "`r`n", "`n"
  [System.IO.File]::WriteAllText($Path, $normalized, $utf8NoBom)
}

if (Test-Path $outputDir) {
  Remove-Item $outputDir -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
New-Item -ItemType Directory -Force -Path $appMacOsDir | Out-Null
New-Item -ItemType Directory -Force -Path $appResourcesDir | Out-Null

& (Join-Path $projectRoot "scripts\generate-icons.ps1")

$filesToCopy = @(
  "index.html",
  "package.json",
  "src\web\app.js",
  "src\web\styles.css",
  "assets\scripts\core\gomoku-ai.js",
  "assets\scripts\core\gomoku-engine.js",
  "assets\scripts\core\gomoku-rules.js",
  "launcher\macos\WuZiLauncher.jxa",
  "scripts\dev-server.mjs",
  "scripts\launch-wuzi-macos.sh",
  "scripts\stop-wuzi-macos.sh"
)

foreach ($relativePath in $filesToCopy) {
  $sourcePath = Join-Path $projectRoot $relativePath
  $targetPath = Join-Path $appResourcesDir $relativePath
  $targetParent = Split-Path $targetPath -Parent
  New-Item -ItemType Directory -Force -Path $targetParent | Out-Null
  $content = [System.IO.File]::ReadAllText($sourcePath)
  Write-LfFile -Path $targetPath -Content $content
}

Write-LfFile -Path (Join-Path $appContentsDir "Info.plist") -Content ([System.IO.File]::ReadAllText((Join-Path $projectRoot "launcher\macos\Info.plist")))
Write-LfFile -Path (Join-Path $appMacOsDir "WuZiLauncher") -Content ([System.IO.File]::ReadAllText((Join-Path $projectRoot "launcher\macos\WuZiLauncher")))
[System.IO.File]::Copy((Join-Path $projectRoot "assets\icons\wuzilauncher.icns"), (Join-Path $appResourceRootDir "WuZiLauncher.icns"), $true)
Write-LfFile -Path (Join-Path $outputDir "Start-WuZi.command") -Content ([System.IO.File]::ReadAllText((Join-Path $projectRoot "launcher\macos\Start-WuZi.command")))
Write-LfFile -Path (Join-Path $outputDir "Stop-WuZi.command") -Content ([System.IO.File]::ReadAllText((Join-Path $projectRoot "launcher\macos\Stop-WuZi.command")))
Write-LfFile -Path (Join-Path $outputDir "QuickStart.txt") -Content ([System.IO.File]::ReadAllText((Join-Path $projectRoot "launcher\macos\QuickStart.txt")))
Write-LfFile -Path (Join-Path $outputDir "QuickStart_EN.txt") -Content ([System.IO.File]::ReadAllText((Join-Path $projectRoot "launcher\macos\QuickStart_EN.txt")))

if (Test-Path $zipPath) {
  Remove-Item $zipPath -Force
}

if (Test-Path $tarGzPath) {
  Remove-Item $tarGzPath -Force
}

New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null

$packageFiles = @(
  (Join-Path $outputDir "WuZiLauncher.app"),
  (Join-Path $outputDir "Start-WuZi.command"),
  (Join-Path $outputDir "Stop-WuZi.command"),
  (Join-Path $outputDir "QuickStart.txt"),
  (Join-Path $outputDir "QuickStart_EN.txt")
)

Compress-Archive -Path $packageFiles -DestinationPath $zipPath -Force
python $pythonPackager $outputDir $tarGzPath
Write-Host "Published macOS package to: $zipPath"
Write-Host "Published macOS package to: $tarGzPath"
