$ErrorActionPreference = "Stop"

$projectRoot = Split-Path $PSScriptRoot -Parent
$outputDir = Join-Path $projectRoot "dist\WuZiLauncher-macos"
$runtimeDir = Join-Path $outputDir ".runtime-macos"
$releaseDir = Join-Path $projectRoot "release"
$packageJsonPath = Join-Path $projectRoot "package.json"
$package = Get-Content $packageJsonPath -Raw | ConvertFrom-Json
$version = $package.version
$zipPath = Join-Path $releaseDir ("WuZiLauncher-macos-v{0}.zip" -f $version)

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
New-Item -ItemType Directory -Force -Path $runtimeDir | Out-Null
Get-ChildItem $runtimeDir -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

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
  $targetPath = Join-Path $outputDir $relativePath
  $targetParent = Split-Path $targetPath -Parent
  New-Item -ItemType Directory -Force -Path $targetParent | Out-Null
  Copy-Item $sourcePath $targetPath -Force
}

$startCommand = @'
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$SCRIPT_DIR/scripts/launch-wuzi-macos.sh"
'@

$stopCommand = @'
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$SCRIPT_DIR/scripts/stop-wuzi-macos.sh"
'@

$quickStartCn = @'
五子棋 macOS 便携版

1. 双击 Start-WuZi.command
2. 首次运行如果被系统拦截，请在“系统设置 -> 隐私与安全性”中允许执行
3. 程序会自动打开浏览器
4. 关闭时双击 Stop-WuZi.command

说明：
- 需要 Node.js，或 Python 3
- 运行日志保存在 .runtime-macos 目录
'@

$quickStartEn = @'
WuZi Gomoku macOS Portable

1. Double-click Start-WuZi.command
2. If macOS blocks the first run, allow it in System Settings -> Privacy & Security
3. The launcher will open your browser automatically
4. Double-click Stop-WuZi.command to stop the local server

Notes:
- Requires Node.js or Python 3
- Runtime logs are stored in the .runtime-macos folder
'@

[System.IO.File]::WriteAllText((Join-Path $outputDir "Start-WuZi.command"), $startCommand, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText((Join-Path $outputDir "Stop-WuZi.command"), $stopCommand, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText((Join-Path $outputDir "QuickStart.txt"), $quickStartCn, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText((Join-Path $outputDir "QuickStart_EN.txt"), $quickStartEn, [System.Text.Encoding]::UTF8)

if (Test-Path $zipPath) {
  Remove-Item $zipPath -Force
}

New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null

$packageFiles = @(
  (Join-Path $outputDir "Start-WuZi.command"),
  (Join-Path $outputDir "Stop-WuZi.command"),
  (Join-Path $outputDir "QuickStart.txt"),
  (Join-Path $outputDir "QuickStart_EN.txt"),
  (Join-Path $outputDir "index.html"),
  (Join-Path $outputDir "package.json"),
  (Join-Path $outputDir "src"),
  (Join-Path $outputDir "assets"),
  (Join-Path $outputDir "scripts")
)

Compress-Archive -Path $packageFiles -DestinationPath $zipPath -Force
Write-Host "Published macOS package to: $zipPath"
