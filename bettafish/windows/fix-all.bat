@echo off
chcp 65001 >nul 2>&1

cls
echo.
echo ========================================
echo   BettaFish One-Click Fix Tool
echo   Fix ALL encoding issues
echo ========================================
echo.
echo This tool will convert ALL PowerShell scripts to UTF-8 with BOM:
echo.
echo   [1] docker-deploy.ps1        (v3.8.3 deployment)
echo   [2] diagnose.ps1              (Diagnostics)
echo   [3] docker-deploy-v4.ps1      (v4.0 deployment)
echo   [4] quick-fix.ps1             (Image fix)
echo.
echo ----------------------------------------
echo.

set /p CONFIRM="Continue? (Y/N): "

if /i not "%CONFIRM%"=="Y" (
    echo.
    echo Cancelled by user.
    pause
    exit /b 0
)

echo.
echo ========================================
echo   Processing files...
echo ========================================
echo.

set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%fix-encoding.ps1"

if not exist "%PS_SCRIPT%" (
    echo [ERROR] Cannot find: fix-encoding.ps1
    echo.
    pause
    exit /b 1
)

powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%PS_SCRIPT%" -All

echo.
echo ========================================
echo   All Done!
echo ========================================
echo.
echo Next steps:
echo   1. You can now run: docker-deploy.bat
echo   2. Or run v4.0: docker-deploy-v4.bat
echo   3. Or fix images: quick-fix.bat
echo.
pause
