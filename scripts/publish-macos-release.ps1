$ErrorActionPreference = "Stop"

$projectRoot = Split-Path $PSScriptRoot -Parent
$outputDir = Join-Path $projectRoot "dist\WuZiLauncher-macos"
$appBundleDir = Join-Path $outputDir "WuZiLauncher.app"
$appContentsDir = Join-Path $appBundleDir "Contents"
$appMacOsDir = Join-Path $appContentsDir "MacOS"
$appResourcesDir = Join-Path $appContentsDir "Resources\app"
$releaseDir = Join-Path $projectRoot "release"
$packageJsonPath = Join-Path $projectRoot "package.json"
$package = Get-Content $packageJsonPath -Raw | ConvertFrom-Json
$version = $package.version
$zipPath = Join-Path $releaseDir ("WuZiLauncher-macos-v{0}.zip" -f $version)
$tarGzPath = Join-Path $releaseDir ("WuZiLauncher-macos-v{0}.tar.gz" -f $version)
$pythonPackager = Join-Path $projectRoot "scripts\package-macos-tar.py"

if (Test-Path $outputDir) {
  Remove-Item $outputDir -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
New-Item -ItemType Directory -Force -Path $appMacOsDir | Out-Null
New-Item -ItemType Directory -Force -Path $appResourcesDir | Out-Null

$filesToCopy = @(
  "index.html",
  "package.json",
  "src\web\app.js",
  "src\web\styles.css",
  "assets\scripts\core\gomoku-ai.js",
  "assets\scripts\core\gomoku-engine.js",
  "assets\scripts\core\gomoku-rules.js",
  "scripts\dev-server.mjs",
  "scripts\launch-wuzi-macos.sh",
  "scripts\stop-wuzi-macos.sh"
)

foreach ($relativePath in $filesToCopy) {
  $sourcePath = Join-Path $projectRoot $relativePath
  $targetPath = Join-Path $appResourcesDir $relativePath
  $targetParent = Split-Path $targetPath -Parent
  New-Item -ItemType Directory -Force -Path $targetParent | Out-Null
  Copy-Item $sourcePath $targetPath -Force
}

Copy-Item (Join-Path $projectRoot "launcher\macos\Info.plist") (Join-Path $appContentsDir "Info.plist") -Force
Copy-Item (Join-Path $projectRoot "launcher\macos\WuZiLauncher") (Join-Path $appMacOsDir "WuZiLauncher") -Force
Copy-Item (Join-Path $projectRoot "launcher\macos\Start-WuZi.command") (Join-Path $outputDir "Start-WuZi.command") -Force
Copy-Item (Join-Path $projectRoot "launcher\macos\Stop-WuZi.command") (Join-Path $outputDir "Stop-WuZi.command") -Force
Copy-Item (Join-Path $projectRoot "launcher\macos\QuickStart.txt") (Join-Path $outputDir "QuickStart.txt") -Force
Copy-Item (Join-Path $projectRoot "launcher\macos\QuickStart_EN.txt") (Join-Path $outputDir "QuickStart_EN.txt") -Force

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
