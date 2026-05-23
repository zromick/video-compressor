# Install "Compress Videos" to Windows right-click context menu
# Run as Administrator

param(
    [switch]$Uninstall
)

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click this script and select 'Run as Administrator'" -ForegroundColor Yellow
    Write-Host "`nPress any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$mainScript = Join-Path $scriptDir "compress-videos.ps1"

# Registry path for folder context menu
$regPath = "Registry::HKEY_CLASSES_ROOT\Directory\shell\CompressVideos"
$regCommandPath = "$regPath\command"

if ($Uninstall) {
    Write-Host "Removing 'Compress Videos' from context menu..." -ForegroundColor Yellow
    if (Test-Path $regPath) {
        Remove-Item -Path $regPath -Recurse -Force
        Write-Host "Successfully removed!" -ForegroundColor Green
    } else {
        Write-Host "Context menu entry not found (already removed?)" -ForegroundColor Gray
    }
} else {
    Write-Host "Installing 'Compress Videos' to context menu..." -ForegroundColor Cyan

    # Create registry keys
    New-Item -Path $regPath -Force | Out-Null
    New-Item -Path $regCommandPath -Force | Out-Null

    # Set menu text
    Set-ItemProperty -Path $regPath -Name "(Default)" -Value "Compress Videos Here"
    Set-ItemProperty -Path $regPath -Name "Icon" -Value "shell32.dll,165"  # Video camera icon

    # Set command
    $command = "powershell.exe -ExecutionPolicy Bypass -NoExit -File `"$mainScript`" -Path `"%V`""
    Set-ItemProperty -Path $regCommandPath -Name "(Default)" -Value $command

    Write-Host "Successfully installed!" -ForegroundColor Green
    Write-Host "`nYou can now right-click any folder and select 'Compress Videos Here'" -ForegroundColor Cyan
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
