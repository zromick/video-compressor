# Video Compression Script
# Reduces MP4 file sizes using FFmpeg

param(
    [string]$Path = ".",
    [ValidateSet("low", "medium", "high")]
    [string]$Quality = "medium",
    [switch]$NoRecursive,
    [switch]$DeleteOriginal,
    [string]$OutputSuffix = "_compressed",
    [string]$OutputDir = $null,  # Optional: Output to a different directory with mirrored structure
    [switch]$PickFolder  # Show GUI folder picker dialog
)

# Show folder picker if requested
if ($PickFolder) {
    Add-Type -AssemblyName System.Windows.Forms
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select folder containing videos to compress"
    $folderBrowser.ShowNewFolderButton = $false

    $result = $folderBrowser.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $Path = $folderBrowser.SelectedPath
        Write-Host "`nSelected folder: $Path" -ForegroundColor Cyan
        Write-Host ""
    } else {
        Write-Host "No folder selected. Exiting..." -ForegroundColor Yellow
        Write-Host "`nPress any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 0
    }
}

# Check if FFmpeg is installed
function Test-FFmpeg {
    try {
        $null = & ffmpeg -version 2>&1
        return $true
    } catch {
        return $false
    }
}

if (-not (Test-FFmpeg)) {
    Write-Host "FFmpeg is not installed. Install it with:" -ForegroundColor Red
    Write-Host "  winget install FFmpeg" -ForegroundColor Yellow
    Write-Host "Or download from: https://ffmpeg.org/download.html" -ForegroundColor Yellow
    exit 1
}

# Quality presets (CRF values: lower = better quality, higher = smaller file)
$qualitySettings = @{
    "low"    = @{ crf = 28; preset = "faster"; description = "Lowest quality (smallest files)" }
    "medium" = @{ crf = 23; preset = "medium"; description = "Balanced quality/size (recommended)" }
    "high"   = @{ crf = 20; preset = "slow"; description = "Higher quality (larger files)" }
}

$settings = $qualitySettings[$Quality]

Write-Host "`nVideo Compression Settings:" -ForegroundColor Cyan
Write-Host "  Quality: $Quality - $($settings.description)" -ForegroundColor Gray
Write-Host "  CRF: $($settings.crf) | Preset: $($settings.preset)" -ForegroundColor Gray
Write-Host "  Recursive: $(-not $NoRecursive)" -ForegroundColor Gray
Write-Host "  Keep originals: $(-not $DeleteOriginal) (creates _compressed.mp4 files)" -ForegroundColor Gray
if ($OutputDir) {
    Write-Host "  Output directory: $OutputDir (mirrored structure)" -ForegroundColor Gray
}
Write-Host ""

# Find all video files (recursive by default)
$videoExtensions = @("*.mp4", "*.mov", "*.avi", "*.mkv", "*.wmv", "*.flv", "*.webm", "*.m4v", "*.3gp", "*.mpg", "*.mpeg", "*.m2v", "*.ogv")
$searchPath = Resolve-Path $Path
$files = if ($NoRecursive) {
    Get-ChildItem -Path $searchPath -Include $videoExtensions -File
} else {
    Get-ChildItem -Path $searchPath -Include $videoExtensions -File -Recurse
}

# Filter out already compressed files
if ($OutputDir) {
    # When using output directory, skip files that already exist in the output
    $files = $files | Where-Object {
        $relativeDir = $_.Directory.FullName.Substring($searchPath.Path.Length).TrimStart('\', '/')
        $outputDirectory = Join-Path $OutputDir $relativeDir
        $outputPath = Join-Path $outputDirectory $_.Name
        -not (Test-Path $outputPath)
    }
} else {
    # When outputting to same directory, skip files with _compressed suffix
    $files = $files | Where-Object { $_.Name -notmatch "$OutputSuffix\.mp4$" }
}

if ($files.Count -eq 0) {
    Write-Host "No video files found in $searchPath" -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($files.Count) video(s) to compress`n" -ForegroundColor Green

$totalOriginalSize = 0
$totalCompressedSize = 0
$processedCount = 0

foreach ($file in $files) {
    $processedCount++

    # Show relative path for nested files
    $relativePath = $file.FullName.Substring($searchPath.Path.Length).TrimStart('\', '/')
    Write-Host "[$processedCount/$($files.Count)] Processing: $relativePath" -ForegroundColor Cyan

    $originalSize = $file.Length
    $totalOriginalSize += $originalSize

    # Generate output path
    if ($OutputDir) {
        # Mirror the folder structure in the output directory
        $relativeDir = $file.Directory.FullName.Substring($searchPath.Path.Length).TrimStart('\', '/')
        $outputDirectory = Join-Path $OutputDir $relativeDir

        # Create output directory if it doesn't exist
        if (-not (Test-Path $outputDirectory)) {
            New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
        }

        # Output file without suffix when using separate output directory
        $outputName = $file.Name
        $outputPath = Join-Path $outputDirectory $outputName
    } else {
        # Output in same directory with suffix
        $outputName = $file.BaseName + $OutputSuffix + $file.Extension
        $outputPath = Join-Path $file.Directory $outputName
    }

    # Compress video
    $ffmpegArgs = @(
        "-i", $file.FullName,
        "-c:v", "libx264",
        "-crf", $settings.crf,
        "-preset", $settings.preset,
        "-c:a", "aac",
        "-b:a", "128k",
        "-movflags", "+faststart",
        "-y",
        $outputPath
    )

    Write-Host "  Compressing..." -ForegroundColor Gray -NoNewline

    # Run FFmpeg and capture output
    $ffmpegOutput = & ffmpeg @ffmpegArgs 2>&1 | Out-String

    if (Test-Path $outputPath) {
        $compressedSize = (Get-Item $outputPath).Length
        $totalCompressedSize += $compressedSize

        $savedBytes = $originalSize - $compressedSize
        $savedPercent = [math]::Round(($savedBytes / $originalSize) * 100, 1)

        Write-Host " Done!" -ForegroundColor Green
        Write-Host "  Original: $([math]::Round($originalSize / 1MB, 2)) MB" -ForegroundColor Gray
        Write-Host "  Compressed: $([math]::Round($compressedSize / 1MB, 2)) MB" -ForegroundColor Gray
        Write-Host "  Saved: $([math]::Round($savedBytes / 1MB, 2)) MB ($savedPercent%)" -ForegroundColor $(if ($savedPercent -gt 0) { "Green" } else { "Yellow" })

        # Delete original only if explicitly requested AND not using separate output directory
        if ($DeleteOriginal -and -not $OutputDir) {
            Remove-Item $file.FullName -Force
            Write-Host "  Deleted original file" -ForegroundColor Yellow
        } elseif ($OutputDir) {
            Write-Host "  Original kept in source location" -ForegroundColor Gray
        } else {
            Write-Host "  Kept original file" -ForegroundColor Gray
        }
    } else {
        Write-Host " Failed!" -ForegroundColor Red
        # Show last few lines of FFmpeg output for debugging
        $errorLines = $ffmpegOutput -split "`n" | Select-Object -Last 5
        Write-Host "  Error: $($errorLines -join ' | ')" -ForegroundColor Red
    }

    Write-Host ""
}

# Summary
$totalSaved = $totalOriginalSize - $totalCompressedSize
$totalSavedPercent = if ($totalOriginalSize -gt 0) {
    [math]::Round(($totalSaved / $totalOriginalSize) * 100, 1)
} else { 0 }

Write-Host "`n" + ("=" * 50) -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan
Write-Host "Files processed: $processedCount"
Write-Host "Total original size: $([math]::Round($totalOriginalSize / 1MB, 2)) MB"
Write-Host "Total compressed size: $([math]::Round($totalCompressedSize / 1MB, 2)) MB"
Write-Host "Total saved: $([math]::Round($totalSaved / 1MB, 2)) MB ($totalSavedPercent%)" -ForegroundColor Green
Write-Host ("=" * 50) -ForegroundColor Cyan
