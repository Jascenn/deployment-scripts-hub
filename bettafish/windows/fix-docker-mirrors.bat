@echo off
chcp 65001 > nul
setlocal

cd /d "%~dp0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0fix-docker-mirrors.ps1"

endlocal
