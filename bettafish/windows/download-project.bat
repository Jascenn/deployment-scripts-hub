@echo off
echo.
echo ========================================
echo   BettaFish Project Download Tool
echo ========================================
echo.

powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0download-project.ps1"

pause
