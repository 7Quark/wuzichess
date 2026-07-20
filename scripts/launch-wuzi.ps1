$NoBrowser = $false
if ($args -contains "-NoBrowser") {
  $NoBrowser = $true
}

$ErrorActionPreference = "Stop"

function Write-Step {
  param([string]$Message)
  Write-Host "[WuZi] $Message"
}

function Test-UrlReady {
  param(
    [string]$Url,
    [int]$TimeoutSeconds = 8
  )

  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    try {
      $response = Invoke-WebRequest -UseBasicParsing $Url -TimeoutSec 2
      if ($response.StatusCode -eq 200) {
        return $true
      }
    } catch {
      Start-Sleep -Milliseconds 300
    }
  }
  return $false
}

function Test-PortFree {
  param([int]$Port)

  $listener = $null
  try {
    $listener = [System.Net.Sockets.TcpListener]::new(
      [System.Net.IPAddress]::Parse("127.0.0.1"),
      $Port
    )
    $listener.Start()
    return $true
  } catch {
    return $false
  } finally {
    if ($listener) {
      $listener.Stop()
    }
  }
}

function Get-FreePort {
  param([int[]]$Candidates)

  foreach ($candidate in $Candidates) {
    if (Test-PortFree -Port $candidate) {
      return $candidate
    }
  }

  throw "No free port found in range 8765-8775."
}

function Get-CommandPath {
  param([string]$Name)

  $command = Get-Command $Name -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }
  return $null
}

$projectRoot = Split-Path $PSScriptRoot -Parent
$runtimeDir = Join-Path $projectRoot ".runtime"
$statePath = Join-Path $runtimeDir "launcher-state.json"
$indexPath = Join-Path $projectRoot "index.html"
$serverPath = Join-Path $projectRoot "scripts\dev-server.mjs"
$spawnHelperPath = Join-Path $projectRoot "scripts\spawn-server.cjs"

Write-Step "Checking project files..."
foreach ($required in @($indexPath, $serverPath, $spawnHelperPath, (Join-Path $projectRoot "package.json"))) {
  if (-not (Test-Path $required)) {
    throw "Missing required file: $required"
  }
}

if (-not (Test-Path $runtimeDir)) {
  New-Item -ItemType Directory -Path $runtimeDir | Out-Null
}

if (Test-Path $statePath) {
  try {
    $previous = Get-Content $statePath -Raw | ConvertFrom-Json
    if ($previous.Pid) {
      $existingProcess = Get-Process -Id $previous.Pid -ErrorAction SilentlyContinue
      $existingUrl = "http://127.0.0.1:$($previous.Port)/index.html"
      if ($existingProcess -and (Test-UrlReady -Url $existingUrl -TimeoutSeconds 1)) {
        Write-Step "Existing instance detected."
        if (-not $NoBrowser) {
          Start-Process $existingUrl | Out-Null
        }
        return
      }
    }
  } catch {
  }
}

Write-Step "Checking runtime..."
$nodePath = Get-CommandPath -Name "node"
$pythonPath = Get-CommandPath -Name "python"
$pyPath = Get-CommandPath -Name "py"

$runtime = $null
$filePath = $null
$argumentList = @()

if ($nodePath) {
  $runtime = "node"
  $filePath = $nodePath
} elseif ($pythonPath) {
  $runtime = "python"
  $filePath = $pythonPath
} elseif ($pyPath) {
  $runtime = "py"
  $filePath = $pyPath
} else {
  throw "Node.js or Python 3 is required."
}

$port = Get-FreePort -Candidates (8765..8775)
$url = "http://127.0.0.1:$port/index.html"

if ($runtime -eq "node") {
  Write-Step "Starting local server with Node.js..."
  $argumentList = @($serverPath)
} elseif ($runtime -eq "python") {
  Write-Step "Node.js not found, fallback to Python..."
  $argumentList = @("-m", "http.server", "$port", "--bind", "127.0.0.1")
} else {
  Write-Step "Node.js not found, fallback to Python launcher..."
  $argumentList = @("-3", "-m", "http.server", "$port", "--bind", "127.0.0.1")
}

if ($runtime -eq "node") {
  $pidText = (& $filePath $spawnHelperPath $serverPath $projectRoot "$port").Trim()
  if (-not $pidText) {
    throw "Failed to spawn Node.js server process."
  }
  $process = @{
    Id = [int]$pidText
  }
} else {
  $process = Start-Process `
    -FilePath $filePath `
    -ArgumentList $argumentList `
    -WorkingDirectory $projectRoot `
    -WindowStyle Hidden `
    -PassThru
}

if (-not (Test-UrlReady -Url $url -TimeoutSeconds 8)) {
  try {
    Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
  } catch {
  }
  throw "Server failed to start."
}

@{
  Pid = $process.Id
  Port = $port
  Runtime = $runtime
  Url = $url
  StartedAt = (Get-Date).ToString("s")
} | ConvertTo-Json | Set-Content -Path $statePath -Encoding UTF8

Write-Step "Server ready: $url"
if (-not $NoBrowser) {
  Write-Step "Opening browser..."
  Start-Process $url | Out-Null
}
