$ErrorActionPreference = "Stop"

$projectRoot = Split-Path $PSScriptRoot -Parent
$iconDir = Join-Path $projectRoot "assets\icons"

Add-Type -AssemblyName System.Drawing

function New-IconBitmap {
  param(
    [int]$Size
  )

  $bitmap = New-Object System.Drawing.Bitmap($Size, $Size)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $graphics.Clear([System.Drawing.Color]::Transparent)

  $backgroundRect = New-Object System.Drawing.RectangleF -ArgumentList @([single]0, [single]0, [single]$Size, [single]$Size)
  $backgroundBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    $backgroundRect,
    [System.Drawing.Color]::FromArgb(255, 237, 202, 122),
    [System.Drawing.Color]::FromArgb(255, 167, 104, 45),
    135.0
  )
  $graphics.FillEllipse($backgroundBrush, 24, 24, $Size - 48, $Size - 48)

  $rimPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(210, 104, 58, 24), [Math]::Max(6, [int]($Size * 0.03)))
  $graphics.DrawEllipse($rimPen, 24, 24, $Size - 48, $Size - 48)

  $gridPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(185, 94, 58, 30), [Math]::Max(2, [int]($Size * 0.008)))
  $start = [int]($Size * 0.27)
  $end = [int]($Size * 0.73)
  foreach ($step in @(0.00, 0.12, 0.24, 0.36, 0.48)) {
    $offset = [int](($end - $start) * $step)
    $x = $start + $offset
    $y = $start + $offset
    $graphics.DrawLine($gridPen, $x, $start, $x, $end)
    $graphics.DrawLine($gridPen, $start, $y, $end, $y)
  }

  $stoneRadius = [int]($Size * 0.115)
  $stones = @(
    @{ X = [int]($Size * 0.34); Y = [int]($Size * 0.38); Top = [System.Drawing.Color]::FromArgb(255, 255, 255, 255); Bottom = [System.Drawing.Color]::FromArgb(255, 205, 211, 220) },
    @{ X = [int]($Size * 0.50); Y = [int]($Size * 0.52); Top = [System.Drawing.Color]::FromArgb(255, 84, 84, 84); Bottom = [System.Drawing.Color]::FromArgb(255, 10, 10, 10) },
    @{ X = [int]($Size * 0.66); Y = [int]($Size * 0.36); Top = [System.Drawing.Color]::FromArgb(255, 58, 58, 58); Bottom = [System.Drawing.Color]::FromArgb(255, 0, 0, 0) }
  )

  $shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(55, 0, 0, 0))
  foreach ($stone in $stones) {
    $stoneX = [int]$stone["X"]
    $stoneY = [int]$stone["Y"]
    $stoneTop = [System.Drawing.Color]$stone["Top"]
    $stoneBottom = [System.Drawing.Color]$stone["Bottom"]

    $graphics.FillEllipse($shadowBrush, $stoneX - $stoneRadius + 6, $stoneY - $stoneRadius + 8, $stoneRadius * 2, $stoneRadius * 2)

    $stoneRect = New-Object System.Drawing.RectangleF -ArgumentList @(
      [single]($stoneX - $stoneRadius),
      [single]($stoneY - $stoneRadius),
      [single]($stoneRadius * 2),
      [single]($stoneRadius * 2)
    )
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($stoneRect, $stoneTop, $stoneBottom, 90.0)
    $graphics.FillEllipse($brush, $stoneRect)
    $brush.Dispose()
  }

  $glossPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(110, 255, 255, 255), [Math]::Max(3, [int]($Size * 0.01)))
  $graphics.DrawArc($glossPen, [int]$stones[1]["X"] - $stoneRadius + 10, [int]$stones[1]["Y"] - $stoneRadius + 10, $stoneRadius, $stoneRadius, 180, 95)
  $graphics.DrawArc($glossPen, [int]$stones[2]["X"] - $stoneRadius + 10, [int]$stones[2]["Y"] - $stoneRadius + 8, $stoneRadius, $stoneRadius, 180, 95)

  $numberFont = New-Object System.Drawing.Font("Segoe UI Semibold", [Math]::Max(38, [int]($Size * 0.12)), [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
  $numberBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(225, 120, 27, 27))
  $format = New-Object System.Drawing.StringFormat
  $format.Alignment = [System.Drawing.StringAlignment]::Center
  $format.LineAlignment = [System.Drawing.StringAlignment]::Center
  $graphics.DrawString(
    "5",
    $numberFont,
    $numberBrush,
    (New-Object System.Drawing.RectangleF -ArgumentList @(
      [single]($Size * 0.21),
      [single]($Size * 0.58),
      [single]($Size * 0.58),
      [single]($Size * 0.23)
    )),
    $format
  )

  $numberFont.Dispose()
  $numberBrush.Dispose()
  $format.Dispose()
  $shadowBrush.Dispose()
  $glossPen.Dispose()
  $gridPen.Dispose()
  $rimPen.Dispose()
  $backgroundBrush.Dispose()
  $graphics.Dispose()

  return $bitmap
}

function Save-Png {
  param(
    [System.Drawing.Bitmap]$Bitmap,
    [string]$Path
  )

  $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function Write-Ico {
  param(
    [string]$Path,
    [byte[]]$PngBytes
  )

  $stream = [System.IO.File]::Create($Path)
  $writer = New-Object System.IO.BinaryWriter($stream)

  $writer.Write([UInt16]0)
  $writer.Write([UInt16]1)
  $writer.Write([UInt16]1)
  $writer.Write([byte]0)
  $writer.Write([byte]0)
  $writer.Write([byte]0)
  $writer.Write([byte]0)
  $writer.Write([UInt16]1)
  $writer.Write([UInt16]32)
  $writer.Write([UInt32]$PngBytes.Length)
  $writer.Write([UInt32]22)
  $writer.Write($PngBytes)
  $writer.Flush()
  $writer.Dispose()
  $stream.Dispose()
}

function Write-Icns {
  param(
    [string]$Path,
    [hashtable]$Chunks
  )

  function Get-BigEndianUInt32Bytes {
    param(
      [int]$Value
    )

    $bytes = [System.BitConverter]::GetBytes([UInt32]$Value)
    [Array]::Reverse($bytes)
    return [byte[]]$bytes
  }

  $stream = [System.IO.File]::Create($Path)
  $writer = New-Object System.IO.BinaryWriter($stream)
  $ascii = [System.Text.Encoding]::ASCII

  $totalLength = 8
  foreach ($entry in $Chunks.GetEnumerator()) {
    $totalLength += 8 + $entry.Value.Length
  }

  $writer.Write($ascii.GetBytes("icns"))
  $writer.Write([byte[]](Get-BigEndianUInt32Bytes -Value $totalLength))

  foreach ($type in @("ic10", "ic09", "ic08", "ic07", "icp6")) {
    if (-not $Chunks.ContainsKey($type)) {
      continue
    }

    $data = $Chunks[$type]
    $chunkLength = 8 + $data.Length
    $writer.Write($ascii.GetBytes($type))
    $writer.Write([byte[]](Get-BigEndianUInt32Bytes -Value $chunkLength))
    $writer.Write($data)
  }

  $writer.Flush()
  $writer.Dispose()
  $stream.Dispose()
}

New-Item -ItemType Directory -Force -Path $iconDir | Out-Null

$sizes = @(1024, 512, 256, 128, 64)
$pngBytesBySize = @{}

foreach ($size in $sizes) {
  $bitmap = New-IconBitmap -Size $size
  $path = Join-Path $iconDir ("wuzilauncher-{0}.png" -f $size)
  Save-Png -Bitmap $bitmap -Path $path
  $pngBytesBySize[$size] = [System.IO.File]::ReadAllBytes($path)
  $bitmap.Dispose()
}

Write-Ico -Path (Join-Path $iconDir "wuzilauncher.ico") -PngBytes $pngBytesBySize[256]
Write-Icns -Path (Join-Path $iconDir "wuzilauncher.icns") -Chunks @{
  ic10 = $pngBytesBySize[1024]
  ic09 = $pngBytesBySize[512]
  ic08 = $pngBytesBySize[256]
  ic07 = $pngBytesBySize[128]
  icp6 = $pngBytesBySize[64]
}

Write-Host "Generated icons in: $iconDir"
