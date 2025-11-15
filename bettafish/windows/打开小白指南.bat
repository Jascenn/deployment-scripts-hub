@echo off
chcp 65001 > nul

echo.
echo ========================================
echo   BettaFish 小白用户指南
echo   保姆级部署教程
echo ========================================
echo.
echo 正在打开小白用户指南...
echo.

start "" "%~dp0小白用户指南.html"

timeout /t 2 /nobreak > nul
