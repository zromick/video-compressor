@echo off
REM Quick launcher - compresses videos in the current directory
REM Usage: Open PowerShell/CMD in any folder and run this batch file

echo.
echo ========================================
echo Video Compressor
echo ========================================
echo.
echo Compressing videos in: %CD%
echo.

REM Get the directory where this batch file is installed
set SCRIPT_DIR=%~dp0

REM Run the compression script on the current directory
powershell.exe -ExecutionPolicy Bypass -File "%SCRIPT_DIR%compress-videos.ps1" -Path "%CD%"

echo.
echo Done! Press any key to exit...
pause >nul
