@echo off
chcp 65001 > nul

echo.
echo ========================================
echo   BettaFish 使用指南
echo ========================================
echo.
echo 正在打开可视化使用指南...
echo.

start "" "%~dp0使用指南.html"

timeout /t 2 /nobreak > nul
