#Requires -Version 5.1

<#
.SYNOPSIS
    BettaFish 项目自动下载工具

.DESCRIPTION
    从 GitHub 自动下载 BettaFish 项目源码到正确位置
#>

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  BettaFish 项目下载工具" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$targetDir = Join-Path $scriptDir "BettaFish-main"

# 检查是否已存在
if (Test-Path $targetDir) {
    Write-Host "检测到已存在 BettaFish-main 目录" -ForegroundColor Yellow
    Write-Host ""
    $overwrite = Read-Host "是否删除并重新下载? [y/N]"

    if ($overwrite -eq 'y' -or $overwrite -eq 'Y') {
        Write-Host "正在删除旧目录..." -ForegroundColor Yellow
        Remove-Item $targetDir -Recurse -Force
        Write-Host "✓ 已删除" -ForegroundColor Green
    } else {
        Write-Host "保留现有目录，退出下载" -ForegroundColor Gray
        Write-Host ""
        Read-Host "按回车键退出"
        exit 0
    }
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  步骤 1/3: 下载源码" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# 下载选项
Write-Host "请选择下载方式:" -ForegroundColor Yellow
Write-Host "  1. GitHub 官方源（国外速度快）"
Write-Host "  2. GitHub 加速源（国内推荐）"
Write-Host "  3. 使用 Git Clone（需要已安装 Git）"
Write-Host ""

$choice = Read-Host "请输入选项 (1/2/3)"

$downloadUrl = ""
$useGit = $false

switch ($choice) {
    "1" {
        $downloadUrl = "https://github.com/JasonZ93/BettaFish/archive/refs/heads/main.zip"
        Write-Host "使用 GitHub 官方源" -ForegroundColor Cyan
    }
    "2" {
        $downloadUrl = "https://ghproxy.com/https://github.com/JasonZ93/BettaFish/archive/refs/heads/main.zip"
        Write-Host "使用 GitHub 加速源" -ForegroundColor Cyan
    }
    "3" {
        $useGit = $true
        Write-Host "使用 Git Clone" -ForegroundColor Cyan
    }
    default {
        Write-Host "无效选项，使用默认（GitHub 加速源）" -ForegroundColor Yellow
        $downloadUrl = "https://ghproxy.com/https://github.com/JasonZ93/BettaFish/archive/refs/heads/main.zip"
    }
}

Write-Host ""

if ($useGit) {
    # 使用 Git Clone
    try {
        $gitVersion = git --version 2>&1
        Write-Host "检测到 Git: $gitVersion" -ForegroundColor Green
        Write-Host ""
        Write-Host "正在克隆仓库..." -ForegroundColor Yellow

        git clone https://github.com/JasonZ93/BettaFish.git "$targetDir"

        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ 克隆成功" -ForegroundColor Green
        } else {
            throw "Git clone 失败"
        }
    } catch {
        Write-Host "✗ Git 操作失败: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "建议:" -ForegroundColor Yellow
        Write-Host "  1. 检查是否已安装 Git" -ForegroundColor Gray
        Write-Host "  2. 重新运行此脚本并选择选项 1 或 2" -ForegroundColor Gray
        Write-Host ""
        Read-Host "按回车键退出"
        exit 1
    }
} else {
    # 使用 HTTP 下载
    $zipFile = Join-Path $scriptDir "BettaFish-main.zip"

    try {
        Write-Host "下载地址: $downloadUrl" -ForegroundColor Gray
        Write-Host "正在下载，请稍候..." -ForegroundColor Yellow
        Write-Host ""

        # 使用 WebClient 显示进度
        $webClient = New-Object System.Net.WebClient

        # 注册进度事件
        $progressEventHandler = {
            param($sender, $e)
            $received = $e.BytesReceived / 1MB
            $total = $e.TotalBytesToReceive / 1MB
            if ($total -gt 0) {
                $percent = [math]::Round(($received / $total) * 100, 1)
                Write-Host "`r下载进度: $percent% ($([math]::Round($received, 2)) MB / $([math]::Round($total, 2)) MB)" -NoNewline -ForegroundColor Yellow
            }
        }

        Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -Action $progressEventHandler | Out-Null

        # 开始下载
        $downloadTask = $webClient.DownloadFileTaskAsync($downloadUrl, $zipFile)

        while (-not $downloadTask.IsCompleted) {
            Start-Sleep -Milliseconds 100
        }

        # 清理事件
        Get-EventSubscriber | Where-Object {$_.SourceObject -eq $webClient} | Unregister-Event -Force

        Write-Host ""
        Write-Host "✓ 下载完成" -ForegroundColor Green

    } catch {
        Write-Host ""
        Write-Host "✗ 下载失败: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "可能原因:" -ForegroundColor Yellow
        Write-Host "  1. 网络连接问题" -ForegroundColor Gray
        Write-Host "  2. GitHub 访问受限" -ForegroundColor Gray
        Write-Host "  3. 防火墙阻止" -ForegroundColor Gray
        Write-Host ""
        Write-Host "建议:" -ForegroundColor Yellow
        Write-Host "  1. 检查网络连接" -ForegroundColor Gray
        Write-Host "  2. 尝试选择其他下载源" -ForegroundColor Gray
        Write-Host "  3. 手动从浏览器下载: https://github.com/JasonZ93/BettaFish" -ForegroundColor Gray
        Write-Host ""
        Read-Host "按回车键退出"
        exit 1
    }

    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  步骤 2/3: 解压文件" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""

    try {
        Write-Host "正在解压..." -ForegroundColor Yellow

        Expand-Archive -Path $zipFile -DestinationPath $scriptDir -Force

        # GitHub 下载的 ZIP 会解压为 BettaFish-main
        $extractedDir = Join-Path $scriptDir "BettaFish-main"

        # 如果解压后的文件夹名称不对，重命名
        if (-not (Test-Path $extractedDir)) {
            # 可能解压为 BettaFish-main-main 或其他名称
            $possibleDirs = Get-ChildItem -Path $scriptDir -Directory | Where-Object { $_.Name -like "BettaFish*" }
            if ($possibleDirs.Count -gt 0) {
                Move-Item -Path $possibleDirs[0].FullName -Destination $targetDir -Force
            }
        }

        Write-Host "✓ 解压完成" -ForegroundColor Green

    } catch {
        Write-Host "✗ 解压失败: $_" -ForegroundColor Red
        exit 1
    }

    # 清理 ZIP 文件
    Write-Host "清理临时文件..." -ForegroundColor Gray
    Remove-Item $zipFile -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  步骤 3/3: 验证文件" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# 验证关键文件
$composeFile = Join-Path $targetDir "docker-compose.yml"

if (Test-Path $targetDir) {
    Write-Host "✓ 项目目录已创建: $targetDir" -ForegroundColor Green
} else {
    Write-Host "✗ 项目目录不存在" -ForegroundColor Red
    Read-Host "按回车键退出"
    exit 1
}

if (Test-Path $composeFile) {
    Write-Host "✓ docker-compose.yml 文件存在" -ForegroundColor Green
} else {
    Write-Host "✗ 找不到 docker-compose.yml 文件" -ForegroundColor Red
    Write-Host "  目录结构可能不正确" -ForegroundColor Yellow
    Read-Host "按回车键退出"
    exit 1
}

# 显示目录内容
Write-Host ""
Write-Host "项目文件列表:" -ForegroundColor Cyan
Get-ChildItem -Path $targetDir | Select-Object -First 10 | ForEach-Object {
    Write-Host "  $($_.Name)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  下载完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "下一步:" -ForegroundColor Cyan
Write-Host "  运行 docker-deploy.bat 开始部署" -ForegroundColor White
Write-Host ""
Read-Host "按回车键退出"
