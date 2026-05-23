# Test compression on a single file before batch processing
# Usage: .\test-single-file.ps1 -File "path\to\video.mp4" -Quality medium

param(
    [Parameter(Mandatory=$true)]
    [string]$File,
    [ValidateSet("low", "medium", "high")]
    [string]$Quality = "medium"
)

if (-not (Test-Path $File)) {
    Write-Host "File not found: $File" -ForegroundColor Red
    exit 1
}

# Quality presets
$qualitySettings = @{
    "low"    = @{ crf = 28; preset = "faster" }
    "medium" = @{ crf = 23; preset = "medium" }
    "high"   = @{ crf = 20; preset = "slow" }
}

$settings = $qualitySettings[$Quality]
$fileInfo = Get-Item $File
$outputPath = Join-Path $fileInfo.Directory ($fileInfo.BaseName + "_TEST_compressed" + $fileInfo.Extension)

Write-Host "`nTesting compression on:" -ForegroundColor Cyan
Write-Host "  File: $($fileInfo.Name)" -ForegroundColor Gray
Write-Host "  Quality: $Quality (CRF: $($settings.crf))" -ForegroundColor Gray
Write-Host "  Original size: $([math]::Round($fileInfo.Length / 1MB, 2)) MB`n" -ForegroundColor Gray

# Compress
$ffmpegArgs = @(
    "-i", $File,
    "-c:v", "libx264",
    "-crf", $settings.crf,
    "-preset", $settings.preset,
    "-c:a", "aac",
    "-b:a", "128k",
    "-movflags", "+faststart",
    "-y",
    $outputPath
)

Write-Host "Compressing (this may take a while)..." -ForegroundColor Yellow
$ffmpegOutput = & ffmpeg @ffmpegArgs 2>&1 | Out-String

if (Test-Path $outputPath) {
    $compressedInfo = Get-Item $outputPath
    $saved = $fileInfo.Length - $compressedInfo.Length
    $savedPercent = [math]::Round(($saved / $fileInfo.Length) * 100, 1)

    Write-Host "`nDone!" -ForegroundColor Green
    Write-Host "  Compressed size: $([math]::Round($compressedInfo.Length / 1MB, 2)) MB" -ForegroundColor Gray
    Write-Host "  Space saved: $([math]::Round($saved / 1MB, 2)) MB ($savedPercent%)" -ForegroundColor Green
    Write-Host "`nTest file created: $($compressedInfo.Name)" -ForegroundColor Cyan
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "  1. Watch both videos to compare quality" -ForegroundColor Gray
    Write-Host "  2. If quality is good, run compress-videos.ps1 on all files" -ForegroundColor Gray
    Write-Host "  3. If quality is too low, try -Quality high" -ForegroundColor Gray
    Write-Host "  4. If quality is fine, try -Quality low for more space savings" -ForegroundColor Gray
} else {
    Write-Host "`nCompression failed!" -ForegroundColor Red
    Write-Host "`nFFmpeg Output:" -ForegroundColor Yellow
    Write-Host $ffmpegOutput -ForegroundColor Gray
}
