@echo off
REM Universal Video Compressor Launcher
REM Double-click this to select any folder and compress videos

echo.
echo ========================================
echo Video Compressor - Folder Picker
echo ========================================
echo.
echo 1. Select a folder in the dialog
echo 2. Videos will be compressed recursively
echo 3. Originals will be kept safe
echo.

REM Get the directory where this batch file is located
set SCRIPT_DIR=%~dp0

REM Run the compression script with folder picker
powershell.exe -ExecutionPolicy Bypass -File "%SCRIPT_DIR%compress-videos.ps1" -PickFolder
