@echo off
chcp 65001 >nul 2>&1

echo.
echo ========================================
echo   BettaFish 部署工具菜单
echo   Windows 版本
echo ========================================
echo.

set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%scripts\menu.ps1"

if not exist "%PS_SCRIPT%" (
    echo [ERROR] Cannot find: scripts\menu.ps1
    pause
    exit /b 1
)

powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%PS_SCRIPT%"

exit /b %errorlevel%
