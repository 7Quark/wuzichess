$ErrorActionPreference = "Stop"

$projectRoot = Split-Path $PSScriptRoot -Parent
$outputDir = Join-Path $projectRoot "dist\WuZiLauncher"
$runtimeDir = Join-Path $outputDir ".runtime"
$sourceFile = Join-Path $projectRoot "launcher\netfx\WuZiLauncher.cs"
$compiler = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
$outputFile = Join-Path $outputDir "WuZiLauncher.exe"
$indexFile = Join-Path $projectRoot "index.html"
$appJsFile = Join-Path $projectRoot "src\web\app.js"
$stylesFile = Join-Path $projectRoot "src\web\styles.css"
$aiFile = Join-Path $projectRoot "assets\scripts\core\gomoku-ai.js"
$engineFile = Join-Path $projectRoot "assets\scripts\core\gomoku-engine.js"
$rulesFile = Join-Path $projectRoot "assets\scripts\core\gomoku-rules.js"

if (-not (Test-Path $compiler)) {
  throw "csc.exe not found: $compiler"
}

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
New-Item -ItemType Directory -Force -Path $runtimeDir | Out-Null
Get-ChildItem $runtimeDir -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

& $compiler `
  /nologo `
  /target:winexe `
  /optimize+ `
  /platform:x64 `
  "/out:$outputFile" `
  /reference:System.dll `
  /reference:System.Core.dll `
  /reference:System.Drawing.dll `
  /reference:System.Net.Http.dll `
  /reference:System.Windows.Forms.dll `
  "/resource:$indexFile,WuZiLauncher.WebAssets.index.html" `
  "/resource:$appJsFile,WuZiLauncher.WebAssets.src.web.app.js" `
  "/resource:$stylesFile,WuZiLauncher.WebAssets.src.web.styles.css" `
  "/resource:$aiFile,WuZiLauncher.WebAssets.assets.scripts.core.gomoku-ai.js" `
  "/resource:$engineFile,WuZiLauncher.WebAssets.assets.scripts.core.gomoku-engine.js" `
  "/resource:$rulesFile,WuZiLauncher.WebAssets.assets.scripts.core.gomoku-rules.js" `
  $sourceFile

if ($LASTEXITCODE -ne 0) {
  throw "Launcher build failed."
}

$startBat = "@echo off`r`nstart `"`" `"%~dp0WuZiLauncher.exe`"`r`n"
$stopBat = "@echo off`r`n`"%~dp0WuZiLauncher.exe`" --stop`r`n"
$quickStartCn = @'
五子棋 Windows 便携版

1. 双击 Start-WuZi.bat 或 WuZiLauncher.exe
2. 启动器会自动打开浏览器
3. 关闭时双击 Stop-WuZi.bat

说明：
- 不需要安装 Node.js
- 不需要安装 Python
- 运行日志保存在 .runtime 目录
'@

$quickStartEn = @'
WuZi Gomoku Windows Portable

1. Double-click Start-WuZi.bat or WuZiLauncher.exe
2. The launcher will open your browser automatically
3. Double-click Stop-WuZi.bat to close the local server

Notes:
- No Node.js installation required
- No Python installation required
- Runtime logs are stored in the .runtime folder
'@

[System.IO.File]::WriteAllText((Join-Path $outputDir "Start-WuZi.bat"), $startBat, [System.Text.Encoding]::ASCII)
[System.IO.File]::WriteAllText((Join-Path $outputDir "Stop-WuZi.bat"), $stopBat, [System.Text.Encoding]::ASCII)
[System.IO.File]::WriteAllText((Join-Path $outputDir "QuickStart.txt"), $quickStartCn, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText((Join-Path $outputDir "QuickStart_EN.txt"), $quickStartEn, [System.Text.Encoding]::UTF8)

Write-Host "Published launcher to: $outputDir"
