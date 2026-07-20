$ErrorActionPreference = "Stop"

function Write-Step {
  param([string]$Message)
  Write-Host "[WuZi] $Message"
}

$projectRoot = Split-Path $PSScriptRoot -Parent
$runtimeDir = Join-Path $projectRoot ".runtime"
$statePath = Join-Path $runtimeDir "launcher-state.json"

if (-not (Test-Path $statePath)) {
  Write-Step "No running record found."
  return
}

try {
  $state = Get-Content $statePath -Raw | ConvertFrom-Json
} catch {
  Remove-Item $statePath -Force -ErrorAction SilentlyContinue
  Write-Step "Broken state file removed."
  return
}

if ($state.Pid) {
  $process = Get-Process -Id $state.Pid -ErrorAction SilentlyContinue
  if ($process) {
    Stop-Process -Id $state.Pid -Force
    Write-Step "Stopped process $($state.Pid)."
  } else {
    Write-Step "Process already stopped."
  }
}

Remove-Item $statePath -Force -ErrorAction SilentlyContinue
Write-Step "State file removed."
