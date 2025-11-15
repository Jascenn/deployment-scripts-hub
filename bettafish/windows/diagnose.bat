@echo off
setlocal enabledelayedexpansion

chcp 65001 >nul 2>&1

set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%scriptsdiagnose.ps1"

if not exist "%PS_SCRIPT%" (
    echo.
    echo [ERROR] Cannot find PowerShell script: diagnose.ps1
    echo Please ensure diagnose.ps1 is in the same directory
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo   BettaFish Diagnostic Tool
echo   Windows Version
echo ========================================
echo.
echo Starting diagnostic program...
echo.

powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%PS_SCRIPT%"

set "EXIT_CODE=%errorlevel%"

exit /b %EXIT_CODE%
