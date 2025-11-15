@echo off
chcp 65001 > nul

echo.
echo ========================================
echo   BettaFish 新手入门指南
echo   完整部署教程
echo ========================================
echo.
echo 正在打开新手入门指南...
echo.

start "" "%~dp0新手入门指南.html"

timeout /t 2 /nobreak > nul
