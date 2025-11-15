@echo off
echo.
echo ========================================
echo   BettaFish Quick Fix Tool
echo   Manual Docker Image Pull
echo ========================================
echo.

powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0quick-fix.ps1"

pause
