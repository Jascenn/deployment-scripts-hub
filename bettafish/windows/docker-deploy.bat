@echo off
setlocal enabledelayedexpansion

chcp 65001 >nul 2>&1

set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%docker-deploy.ps1"

if not exist "%PS_SCRIPT%" (
    echo.
    echo [ERROR] Cannot find PowerShell script: docker-deploy.ps1
    echo.
    pause
    exit /b 1
)

powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%PS_SCRIPT%"
set "EXIT_CODE=%errorlevel%"

if %EXIT_CODE% equ 0 (
    echo [SUCCESS] Deployment completed!
) else (
    echo [ERROR] Deployment failed with exit code: %EXIT_CODE%
)

pause
exit /b %EXIT_CODE%
