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
    [switch]$PickFolder,  # Show GUI folder picker dialog
    [int]$MaxVideos = 0,  # Optional: Maximum number of videos to process (0 = unlimited)
    [switch]$LogOutput  # Optional: Create timestamped log file of the compression process
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

# Start logging if requested
if ($LogOutput) {
    $timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
    $logPath = Join-Path $PSScriptRoot "output_logs_$timestamp.txt"
    Start-Transcript -Path $logPath -Append | Out-Null
    Write-Host "Logging to: $logPath`n" -ForegroundColor Gray
}

# Quality presets (CRF values: lower = better quality, higher = smaller file)
$qualitySettings = @{
    "low"    = @{ crf = 28; preset = "faster"; description = "Lowest quality (smallest files)"; expectedBitrate = 800 }
    "medium" = @{ crf = 23; preset = "medium"; description = "Balanced quality/size (recommended)"; expectedBitrate = 1500 }
    "high"   = @{ crf = 20; preset = "slow"; description = "Higher quality (larger files)"; expectedBitrate = 2500 }
}

$settings = $qualitySettings[$Quality]

# Function to get video bitrate
function Get-VideoBitrate {
    param([string]$FilePath)
    try {
        $bitrateStr = & ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 $FilePath 2>&1
        if ($bitrateStr -match '^\d+$') {
            return [int]$bitrateStr
        }
        return $null
    } catch {
        return $null
    }
}

# Function to get free disk space on a drive
function Get-FreeDiskSpace {
    param([string]$Path)
    try {
        $drive = (Get-Item $Path).PSDrive
        return $drive.Free
    } catch {
        return $null
    }
}

# Function to get video duration in seconds
function Get-VideoDuration {
    param([string]$FilePath)
    try {
        $durationStr = & ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $FilePath 2>&1
        if ($durationStr -match '^\d+\.?\d*$') {
            return [double]$durationStr
        }
        return $null
    } catch {
        return $null
    }
}

# Function to estimate compressed file size
function Get-EstimatedCompressedSize {
    param(
        [double]$Duration,
        [int]$TargetBitrateKbps,
        [int]$AudioBitrateKbps = 128
    )
    # Formula: (video bitrate + audio bitrate) * duration / 8 = size in KB
    # Convert to bytes
    $totalBitrateKbps = $TargetBitrateKbps + $AudioBitrateKbps
    $estimatedBytes = ($totalBitrateKbps * $Duration * 1000) / 8
    return $estimatedBytes
}

Write-Host "`nVideo Compression Settings:" -ForegroundColor Cyan
Write-Host "  Quality: $Quality - $($settings.description)" -ForegroundColor Gray
Write-Host "  CRF: $($settings.crf) | Preset: $($settings.preset)" -ForegroundColor Gray
Write-Host "  Recursive: $(-not $NoRecursive)" -ForegroundColor Gray
Write-Host "  Keep originals: $(-not $DeleteOriginal) (creates _compressed.mp4 files)" -ForegroundColor Gray
if ($OutputDir) {
    Write-Host "  Output directory: $OutputDir (mirrored structure)" -ForegroundColor Gray
}
if ($MaxVideos -gt 0) {
    Write-Host "  Max videos to process: $MaxVideos" -ForegroundColor Gray
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
    # When outputting to same directory, skip files in two cases:
    # 1. Files with _compressed in the name (already compressed)
    # 2. Files whose compressed version already exists (always .mp4)
    $files = $files | Where-Object {
        $hasCompressedSuffix = $_.BaseName -match "$OutputSuffix$"
        $compressedVersionExists = Test-Path (Join-Path $_.Directory ($_.BaseName + $OutputSuffix + ".mp4"))
        -not ($hasCompressedSuffix -or $compressedVersionExists)
    }
}

if ($files.Count -eq 0) {
    Write-Host "No video files found in $searchPath" -ForegroundColor Yellow
    exit 0
}

# Don't pre-limit files - we'll limit based on successful compressions
Write-Host "Found $($files.Count) video(s) to process" -ForegroundColor Green
if ($MaxVideos -gt 0) {
    Write-Host "Will compress up to $MaxVideos videos (skipped videos don't count toward limit)`n" -ForegroundColor Green
} else {
    Write-Host ""
}

# Determine the output drive for disk space checks
$outputDrive = if ($OutputDir) { $OutputDir } else { $searchPath.Path }

$totalOriginalSize = 0
$totalCompressedSize = 0
$processedCount = 0
$compressedCount = 0
$skippedCount = 0

foreach ($file in $files) {
    # Stop if we've reached the MaxVideos limit (only count compressed videos)
    if ($MaxVideos -gt 0 -and $compressedCount -ge $MaxVideos) {
        Write-Host "`nReached limit of $MaxVideos compressed videos. Stopping." -ForegroundColor Yellow
        break
    }

    $processedCount++

    # Show relative path for nested files
    $relativePath = $file.FullName.Substring($searchPath.Path.Length).TrimStart('\', '/')
    Write-Host "[$processedCount] Processing: $relativePath" -ForegroundColor Cyan

    $originalSize = $file.Length
    $totalOriginalSize += $originalSize

    # Check if there's enough disk space for this video
    $freeSpace = Get-FreeDiskSpace -Path $outputDrive
    if ($freeSpace -ne $null -and $freeSpace -lt $originalSize) {
        Write-Host "  Insufficient disk space! Free: $([math]::Round($freeSpace / 1MB, 2)) MB, Needed: ~$([math]::Round($originalSize / 1MB, 2)) MB" -ForegroundColor Red
        Write-Host "`nStopping compression - not enough disk space for remaining videos" -ForegroundColor Yellow
        break
    }

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
        # Always output as .mp4 since we're encoding with H.264+AAC
        $outputName = $file.BaseName + $OutputSuffix + ".mp4"
        $outputPath = Join-Path $file.Directory $outputName
    }

    # Check if compression would actually save space
    $sourceBitrate = Get-VideoBitrate -FilePath $file.FullName
    $duration = Get-VideoDuration -FilePath $file.FullName

    if ($sourceBitrate -ne $null) {
        $sourceBitrateKbps = [math]::Round($sourceBitrate / 1000, 0)

        # Skip if source is already compressed below our target quality level
        if ($sourceBitrateKbps -lt $settings.expectedBitrate) {
            Write-Host "  Skipping (already efficient at $sourceBitrateKbps kbps, target: $($settings.expectedBitrate) kbps)" -ForegroundColor Yellow
            $skippedCount++
            Write-Host ""
            continue
        }

        # Estimate compressed size and skip if it would be larger
        if ($duration -ne $null) {
            $estimatedSize = Get-EstimatedCompressedSize -Duration $duration -TargetBitrateKbps $settings.expectedBitrate
            if ($estimatedSize -ge $originalSize) {
                Write-Host "  Skipping (estimated compressed size $([math]::Round($estimatedSize / 1MB, 2)) MB >= original $([math]::Round($originalSize / 1MB, 2)) MB)" -ForegroundColor Yellow
                $skippedCount++
                Write-Host ""
                continue
            }
        }
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

    Write-Host "  Compressing (source: $sourceBitrateKbps kbps)..." -ForegroundColor Gray -NoNewline

    # Run FFmpeg and capture output
    $ffmpegOutput = & ffmpeg @ffmpegArgs 2>&1 | Out-String

    if (Test-Path $outputPath) {
        $compressedSize = (Get-Item $outputPath).Length
        $totalCompressedSize += $compressedSize
        $compressedCount++  # Increment successful compression count

        $savedBytes = $originalSize - $compressedSize
        $savedPercent = [math]::Round(($savedBytes / $originalSize) * 100, 1)

        Write-Host " Done!" -ForegroundColor Green
        Write-Host "  Original: $([math]::Round($originalSize / 1MB, 2)) MB" -ForegroundColor Gray
        Write-Host "  Compressed: $([math]::Round($compressedSize / 1MB, 2)) MB" -ForegroundColor Gray
        Write-Host "  Saved: $([math]::Round($savedBytes / 1MB, 2)) MB ($savedPercent%)" -ForegroundColor $(if ($savedPercent -gt 0) { "Green" } else { "Yellow" })
        Write-Host "  Compressed: $compressedCount/$MaxVideos" -ForegroundColor Cyan

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
Write-Host "Files compressed: $compressedCount" -ForegroundColor Green
if ($skippedCount -gt 0) {
    Write-Host "Files skipped (already efficient or would be larger): $skippedCount" -ForegroundColor Yellow
}
Write-Host "Total original size: $([math]::Round($totalOriginalSize / 1MB, 2)) MB"
Write-Host "Total compressed size: $([math]::Round($totalCompressedSize / 1MB, 2)) MB"
Write-Host "Total saved: $([math]::Round($totalSaved / 1MB, 2)) MB ($totalSavedPercent%)" -ForegroundColor Green
Write-Host ("=" * 50) -ForegroundColor Cyan

# Stop logging if it was started
if ($LogOutput) {
    Stop-Transcript | Out-Null
}
