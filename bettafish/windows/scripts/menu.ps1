# BettaFish 部署工具菜单 - PowerShell 版本
# 作者: LIONCC.AI
# 功能: 交互式菜单管理工具

#Requires -Version 5.1

# 设置控制台编码为 UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# 获取脚本所在目录（scripts/）
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
# 设置工作目录为 Windows 主目录（上一级）
$WORK_DIR = Split-Path -Parent $SCRIPT_DIR
Set-Location $WORK_DIR

# 颜色定义
function Write-ColorText {
    param(
        [string]$Text,
        [string]$Color = "White"
    )
    Write-Host $Text -ForegroundColor $Color
}

# 显示标题
function Show-Header {
    Clear-Host
    Write-ColorText "========================================" "Cyan"
    Write-ColorText " BettaFish 部署工具菜单" "Cyan"
    Write-ColorText " Windows 版本" "Cyan"
    Write-ColorText "========================================" "Cyan"
    Write-Host ""
    Write-ColorText "项目作者: LIONCC.AI" "Gray"
    Write-ColorText "官方 API: https://vibecodingapi.ai" "Gray"
    Write-Host ""
}

# 显示菜单选项
function Show-Menu {
    Write-ColorText "请选择操作：" "Yellow"
    Write-Host ""
    Write-ColorText "  1) 部署/更新 BettaFish" "Green"
    Write-ColorText "  2) 系统诊断" "Green"
    Write-ColorText "  3) 下载 BettaFish 源码" "Green"
    Write-ColorText "  4) 修复 Docker 镜像源" "Green"
    Write-Host ""
    Write-ColorText "  5) 启动服务" "Cyan"
    Write-ColorText "  6) 停止服务" "Cyan"
    Write-ColorText "  7) 重启服务" "Cyan"
    Write-ColorText "  8) 查看服务状态" "Cyan"
    Write-ColorText "  9) 查看服务日志" "Cyan"
    Write-Host ""
    Write-ColorText "  d) 打开用户文档" "Magenta"
    Write-ColorText "  h) 显示帮助信息" "Magenta"
    Write-Host ""
    Write-ColorText "  0) 退出" "Red"
    Write-Host ""
}

# 执行脚本
function Invoke-Script {
    param(
        [string]$ScriptName,
        [string]$Description
    )

    # 在 scripts 目录中查找脚本
    $scriptPath = Join-Path $SCRIPT_DIR "$ScriptName.ps1"

    if (Test-Path $scriptPath) {
        Write-Host ""
        Write-ColorText "========================================" "Cyan"
        Write-ColorText " $Description" "Cyan"
        Write-ColorText "========================================" "Cyan"
        Write-Host ""

        & $scriptPath

        Write-Host ""
        Write-ColorText "按任意键返回菜单..." "Yellow"
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } else {
        Write-ColorText "[错误] 未找到脚本: $scriptPath" "Red"
        Write-Host ""
        Write-ColorText "按任意键返回菜单..." "Yellow"
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

# Docker Compose 操作
function Invoke-DockerCompose {
    param(
        [string]$Action,
        [string]$Description
    )

    # 项目目录在工作目录下
    $projectDir = Join-Path $WORK_DIR "BettaFish-main"

    if (-not (Test-Path $projectDir)) {
        Write-ColorText "[错误] 未找到 BettaFish-main 目录" "Red"
        Write-ColorText "[提示] 请先运行部署脚本" "Yellow"
        Write-Host ""
        Write-ColorText "按任意键返回菜单..." "Yellow"
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }

    Write-Host ""
    Write-ColorText "========================================" "Cyan"
    Write-ColorText " $Description" "Cyan"
    Write-ColorText "========================================" "Cyan"
    Write-Host ""

    Set-Location $projectDir

    switch ($Action) {
        "up" {
            Write-ColorText "[INFO] 正在启动服务..." "Cyan"
            docker-compose up -d
            if ($LASTEXITCODE -eq 0) {
                Write-ColorText "[SUCCESS] 服务已启动" "Green"
                Write-Host ""
                Write-ColorText "访问地址：" "Yellow"
                Write-ColorText "  主服务:        http://localhost:5001" "White"
                Write-ColorText "  Insight引擎:   http://localhost:8501" "White"
                Write-ColorText "  Media引擎:     http://localhost:8502" "White"
                Write-ColorText "  Query引擎:     http://localhost:8503" "White"
                Write-Host ""
                Write-ColorText "[提示] 首次访问请等待 30-60 秒" "Yellow"
            } else {
                Write-ColorText "[ERROR] 服务启动失败" "Red"
            }
        }
        "stop" {
            Write-ColorText "[INFO] 正在停止服务..." "Cyan"
            docker-compose stop
            if ($LASTEXITCODE -eq 0) {
                Write-ColorText "[SUCCESS] 服务已停止" "Green"
            } else {
                Write-ColorText "[ERROR] 服务停止失败" "Red"
            }
        }
        "restart" {
            Write-ColorText "[INFO] 正在重启服务..." "Cyan"
            docker-compose restart
            if ($LASTEXITCODE -eq 0) {
                Write-ColorText "[SUCCESS] 服务已重启" "Green"
            } else {
                Write-ColorText "[ERROR] 服务重启失败" "Red"
            }
        }
        "ps" {
            Write-ColorText "[INFO] 服务状态：" "Cyan"
            Write-Host ""
            docker-compose ps
        }
        "logs" {
            Write-ColorText "[INFO] 查看服务日志（按 Ctrl+C 退出）" "Cyan"
            Write-Host ""
            docker-compose logs -f
        }
    }

    Set-Location $SCRIPT_DIR

    if ($Action -ne "logs") {
        Write-Host ""
        Write-ColorText "按任意键返回菜单..." "Yellow"
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

# 打开文档
function Open-Documentation {
    # 文档目录在工作目录下
    $docsDir = Join-Path $WORK_DIR "docs"

    if (Test-Path $docsDir) {
        Write-Host ""
        Write-ColorText "========================================" "Cyan"
        Write-ColorText " 打开用户文档" "Cyan"
        Write-ColorText "========================================" "Cyan"
        Write-Host ""
        Write-ColorText "可用文档：" "Yellow"
        Write-Host ""
        Write-ColorText "  1) 新手入门指南.html（推荐）" "Green"
        Write-ColorText "  2) 使用指南.html" "Green"
        Write-ColorText "  3) 问题修复说明.md" "Green"
        Write-ColorText "  4) 打开 docs 文件夹" "Green"
        Write-Host ""
        Write-ColorText "  0) 返回主菜单" "Red"
        Write-Host ""

        $choice = Read-Host "请选择"

        switch ($choice) {
            "1" {
                $file = Join-Path $docsDir "新手入门指南.html"
                if (Test-Path $file) {
                    Start-Process $file
                    Write-ColorText "[SUCCESS] 已打开新手入门指南" "Green"
                }
            }
            "2" {
                $file = Join-Path $docsDir "使用指南.html"
                if (Test-Path $file) {
                    Start-Process $file
                    Write-ColorText "[SUCCESS] 已打开使用指南" "Green"
                }
            }
            "3" {
                $file = Join-Path $docsDir "问题修复说明.md"
                if (Test-Path $file) {
                    Start-Process notepad $file
                    Write-ColorText "[SUCCESS] 已打开问题修复说明" "Green"
                }
            }
            "4" {
                Start-Process explorer $docsDir
                Write-ColorText "[SUCCESS] 已打开 docs 文件夹" "Green"
            }
            "0" {
                return
            }
            default {
                Write-ColorText "[ERROR] 无效选择" "Red"
            }
        }

        Write-Host ""
        Write-ColorText "按任意键返回菜单..." "Yellow"
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } else {
        Write-ColorText "[错误] 未找到 docs 目录" "Red"
        Write-Host ""
        Write-ColorText "按任意键返回菜单..." "Yellow"
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

# 显示帮助
function Show-Help {
    Write-Host ""
    Write-ColorText "========================================" "Cyan"
    Write-ColorText " 帮助信息" "Cyan"
    Write-ColorText "========================================" "Cyan"
    Write-Host ""
    Write-ColorText "快速开始：" "Yellow"
    Write-ColorText "  1. 首次使用：选择 '1' 部署 BettaFish" "White"
    Write-ColorText "  2. 启动服务：选择 '5' 启动服务" "White"
    Write-ColorText "  3. 查看状态：选择 '8' 查看服务状态" "White"
    Write-Host ""
    Write-ColorText "常用操作：" "Yellow"
    Write-ColorText "  - 部署：安装或更新 BettaFish" "White"
    Write-ColorText "  - 诊断：检查系统和服务状态" "White"
    Write-ColorText "  - 启动：启动 BettaFish 服务" "White"
    Write-ColorText "  - 停止：停止 BettaFish 服务" "White"
    Write-Host ""
    Write-ColorText "获取帮助：" "Yellow"
    Write-ColorText "  - 文档：选择 'd' 打开用户文档" "White"
    Write-ColorText "  - 在线：https://github.com/Jascenn/deployment-scripts-hub" "White"
    Write-Host ""
    Write-ColorText "按任意键返回菜单..." "Yellow"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# 主循环
function Start-Menu {
    while ($true) {
        Show-Header
        Show-Menu

        $choice = Read-Host "请输入选项"

        switch ($choice.ToLower()) {
            "1" {
                Invoke-Script "docker-deploy" "部署/更新 BettaFish"
            }
            "2" {
                Invoke-Script "diagnose" "系统诊断"
            }
            "3" {
                Invoke-Script "download-project" "下载 BettaFish 源码"
            }
            "4" {
                Invoke-Script "fix-docker-mirrors" "修复 Docker 镜像源"
            }
            "5" {
                Invoke-DockerCompose "up" "启动服务"
            }
            "6" {
                Invoke-DockerCompose "stop" "停止服务"
            }
            "7" {
                Invoke-DockerCompose "restart" "重启服务"
            }
            "8" {
                Invoke-DockerCompose "ps" "查看服务状态"
            }
            "9" {
                Invoke-DockerCompose "logs" "查看服务日志"
            }
            "d" {
                Open-Documentation
            }
            "h" {
                Show-Help
            }
            "0" {
                Write-Host ""
                Write-ColorText "感谢使用 BettaFish 部署工具！" "Green"
                Write-Host ""
                exit 0
            }
            default {
                Write-Host ""
                Write-ColorText "[错误] 无效的选项，请重新选择" "Red"
                Start-Sleep -Seconds 1
            }
        }
    }
}

# 启动菜单
Start-Menu
