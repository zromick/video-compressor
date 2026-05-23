# Video Compressor - Select Any Folder
# Run this script from anywhere, then pick a folder to compress

param(
    [ValidateSet("low", "medium", "high")]
    [string]$Quality = "medium",
    [switch]$NoRecursive,
    [switch]$DeleteOriginal
)

Add-Type -AssemblyName System.Windows.Forms

# Show folder picker dialog
$folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
$folderBrowser.Description = "Select folder containing videos to compress"
$folderBrowser.ShowNewFolderButton = $false

$result = $folderBrowser.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    $selectedPath = $folderBrowser.SelectedPath
    Write-Host "`nSelected folder: $selectedPath" -ForegroundColor Cyan
    Write-Host ""

    # Get the directory where this script is located
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $mainScript = Join-Path $scriptDir "compress-videos.ps1"

    if (Test-Path $mainScript) {
        # Build arguments
        $args = @("-Path", $selectedPath, "-Quality", $Quality)
        if ($NoRecursive) { $args += "-NoRecursive" }
        if ($DeleteOriginal) { $args += "-DeleteOriginal" }

        # Run the main compression script
        & $mainScript @args
    } else {
        Write-Host "Error: compress-videos.ps1 not found in script directory!" -ForegroundColor Red
        Write-Host "Make sure this script is in the same folder as compress-videos.ps1" -ForegroundColor Yellow
    }
} else {
    Write-Host "No folder selected. Exiting..." -ForegroundColor Yellow
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
