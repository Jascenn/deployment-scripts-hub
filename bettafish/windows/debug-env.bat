@echo off
chcp 65001 > nul
setlocal

cd /d "%~dp0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0debug-env.ps1"

endlocal
