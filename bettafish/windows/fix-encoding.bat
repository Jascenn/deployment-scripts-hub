@echo off
chcp 65001 >nul 2>&1

echo.
echo ========================================
echo   BettaFish Encoding Fix Tool v3.0
echo   Converting to UTF-8 with BOM
echo ========================================
echo.

set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%fix-encoding-v3.ps1"

if not exist "%PS_SCRIPT%" (
    echo [ERROR] Cannot find: fix-encoding-v3.ps1
    pause
    exit /b 1
)

echo Choose which files to fix:
echo.
echo   1. Core files only (docker-deploy.ps1, diagnose.ps1)
echo   2. All files (including v4.0 and quick-fix)
echo.
set /p CHOICE="Enter choice [1-2]: "

if "%CHOICE%"=="2" (
    echo.
    echo Running encoding fix for ALL files...
    echo.
    powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%PS_SCRIPT%" -All
) else (
    echo.
    echo Running encoding fix for CORE files only...
    echo.
    powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%PS_SCRIPT%"
)

echo.
echo ========================================
echo   Done!
echo ========================================
echo.
pause
