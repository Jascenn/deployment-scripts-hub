@echo off
chcp 65001 >nul 2>&1

echo.
echo ========================================
echo   BettaFish Intelligent Fix Tool
echo   Windows Version
echo ========================================
echo.

set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%scripts\fix-all.ps1"

if not exist "%PS_SCRIPT%" (
    echo [ERROR] Cannot find: scripts\fix-all.ps1
    pause
    exit /b 1
)

powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%PS_SCRIPT%"

exit /b %errorlevel%
