#Requires -Version 5.1

<#
.SYNOPSIS
    BettaFish 诊断工具 - Windows PowerShell 版本

.DESCRIPTION
    自动诊断 BettaFish 部署环境和运行状态
    检测常见问题并提供解决方案

.NOTES
    版本: v1.0.0-windows
    作者: LIONCC.AI
    日期: 2025-11-15
#>

# ================================================================
# 全局变量
# ================================================================

$ErrorActionPreference = "Continue"
$SCRIPT_VERSION = "v1.0.0-windows"

# 颜色输出函数
function Write-CheckResult {
    param(
        [string]$Item,
        [bool]$Success,
        [string]$Message = ""
    )

    if ($Success) {
        Write-Host "[✓] " -NoNewline -ForegroundColor Green
    } else {
        Write-Host "[✗] " -NoNewline -ForegroundColor Red
    }

    Write-Host "$Item" -NoNewline

    if ($Message) {
        Write-Host " - $Message" -ForegroundColor Gray
    } else {
        Write-Host ""
    }
}

function Write-Title {
    param([string]$Title)
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
}

# ================================================================
# 诊断函数
# ================================================================

function Test-Environment {
    Write-Title "1. 环境检查"

    # PowerShell 版本
    $psVersion = $PSVersionTable.PSVersion
    $psOK = $psVersion.Major -ge 5
    Write-CheckResult "PowerShell $($psVersion.Major).$($psVersion.Minor)" $psOK

    # 管理员权限
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    Write-CheckResult "管理员权限" $isAdmin $(if ($isAdmin) { "已获取" } else { "未获取（某些功能受限）" })

    # Docker Desktop 安装
    try {
        $dockerVersion = docker --version 2>$null
        $dockerInstalled = $LASTEXITCODE -eq 0
        Write-CheckResult "Docker Desktop" $dockerInstalled $dockerVersion
    } catch {
        Write-CheckResult "Docker Desktop" $false "未安装"
    }

    # Docker 运行状态
    try {
        $null = docker ps 2>&1
        $dockerRunning = $LASTEXITCODE -eq 0
        Write-CheckResult "Docker 服务" $dockerRunning
    } catch {
        Write-CheckResult "Docker 服务" $false "未运行"
    }

    # 网络连接
    try {
        $networkOK = Test-Connection -ComputerName "www.google.com" -Count 1 -Quiet -ErrorAction SilentlyContinue
        if (-not $networkOK) {
            $networkOK = Test-Connection -ComputerName "www.baidu.com" -Count 1 -Quiet -ErrorAction SilentlyContinue
        }
        Write-CheckResult "网络连接" $networkOK
    } catch {
        Write-CheckResult "网络连接" $false "无法连接"
    }
}

function Test-ProjectFiles {
    Write-Title "2. 项目文件检查"

    $scriptDir = $PSScriptRoot
    $projectDir = Join-Path $scriptDir "BettaFish-main"

    # BettaFish-main 目录
    $projectExists = Test-Path $projectDir
    Write-CheckResult "BettaFish-main 目录" $projectExists $projectDir

    if ($projectExists) {
        # docker-compose.yml
        $composeFile = Join-Path $projectDir "docker-compose.yml"
        $composeExists = Test-Path $composeFile
        Write-CheckResult "docker-compose.yml" $composeExists

        # .env 文件
        $envFile = Join-Path $projectDir ".env"
        $envExists = Test-Path $envFile
        Write-CheckResult ".env 文件" $envExists $(if ($envExists) { "已配置" } else { "未配置" })

        # 检查 .env 内容
        if ($envExists) {
            $envContent = Get-Content $envFile -Raw
            $hasOpenAI = $envContent -match "OPENAI_API_KEY=.+"
            Write-CheckResult "  OpenAI API Key" $hasOpenAI
        }
    }
}

function Test-DockerImages {
    Write-Title "3. Docker 镜像检查"

    try {
        # PostgreSQL 镜像
        $postgresExists = docker images postgres:15 --format "{{.Repository}}" 2>$null
        Write-CheckResult "postgres:15" ($postgresExists -eq "postgres")

        # BettaFish 镜像
        $bettafishExists = docker images ghcr.io/jasonz93/bettafish:latest --format "{{.Repository}}" 2>$null
        Write-CheckResult "bettafish:latest" ($bettafishExists -eq "ghcr.io/jasonz93/bettafish")

    } catch {
        Write-CheckResult "镜像检查" $false "无法检查镜像"
    }
}

function Test-DockerContainers {
    Write-Title "4. Docker 容器状态"

    try {
        $containers = docker ps --format "{{.Names}}\t{{.Status}}\t{{.Ports}}" 2>$null

        if ($containers) {
            $containerArray = $containers -split "`n"
            foreach ($container in $containerArray) {
                $parts = $container -split "`t"
                if ($parts.Count -ge 2) {
                    $name = $parts[0]
                    $status = $parts[1]
                    $running = $status -like "*Up*"

                    Write-CheckResult $name $running $status
                }
            }
        } else {
            Write-Host "  没有运行中的容器" -ForegroundColor Gray
        }

    } catch {
        Write-CheckResult "容器检查" $false "无法检查容器"
    }
}

function Test-Ports {
    Write-Title "5. 端口占用检查"

    $portsToCheck = @(5000, 5001, 8501, 8502, 8503, 5432)

    foreach ($port in $portsToCheck) {
        try {
            $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, $port)
            $listener.Start()
            $listener.Stop()
            Write-CheckResult "端口 $port" $true "可用"
        } catch {
            # 检查是否被 Docker 容器使用
            $usedByDocker = $false
            try {
                $dockerPorts = docker ps --format "{{.Ports}}" 2>$null
                if ($dockerPorts -match "$port") {
                    $usedByDocker = $true
                }
            } catch {}

            if ($usedByDocker) {
                Write-CheckResult "端口 $port" $true "被 Docker 容器使用（正常）"
            } else {
                Write-CheckResult "端口 $port" $false "被占用"
            }
        }
    }
}

function Test-Firewall {
    Write-Title "6. 防火墙规则检查"

    try {
        $rules = Get-NetFirewallRule -DisplayName "BettaFish*" -ErrorAction SilentlyContinue

        if ($rules) {
            foreach ($rule in $rules) {
                $enabled = $rule.Enabled -eq "True"
                Write-CheckResult $rule.DisplayName $enabled $(if ($enabled) { "已启用" } else { "已禁用" })
            }
        } else {
            Write-Host "  未找到 BettaFish 防火墙规则" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  无法检查防火墙规则（需要管理员权限）" -ForegroundColor Yellow
    }
}

function Test-NetworkAccess {
    Write-Title "7. 服务访问测试"

    # 获取本地 IP
    $localIP = Get-NetIPAddress -AddressFamily IPv4 |
               Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } |
               Select-Object -First 1 -ExpandProperty IPAddress

    Write-Host "  本地 IP: $localIP" -ForegroundColor Cyan

    # 尝试获取公网 IP
    $publicIP = $null
    try {
        # 使用 ipinfo.io (返回纯文本)
        $publicIP = (Invoke-WebRequest -Uri "https://ipinfo.io/ip" -TimeoutSec 3 -UseBasicParsing).Content.Trim()
    } catch {
        try {
            # 备用: api.ipify.org
            $publicIP = (Invoke-WebRequest -Uri "https://api.ipify.org" -TimeoutSec 3 -UseBasicParsing).Content.Trim()
        } catch {
            # 无法获取
        }
    }

    if ($publicIP -and $publicIP -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
        Write-Host "  公网 IP: $publicIP" -ForegroundColor Cyan
    } else {
        Write-Host "  公网 IP: 无法获取" -ForegroundColor Gray
    }

    # 测试服务访问
    Write-Host ""
    $portsToTest = @(
        @{Port=5000; Name="BettaFish 主服务"},
        @{Port=8501; Name="Insight Engine"},
        @{Port=8502; Name="Media Engine"},
        @{Port=8503; Name="Query Engine"}
    )

    foreach ($service in $portsToTest) {
        $port = $service.Port
        $name = $service.Name

        try {
            $response = Invoke-WebRequest -Uri "http://localhost:$port" -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
            Write-CheckResult $name $true "http://localhost:$port (HTTP $($response.StatusCode))"
        } catch {
            # 端口可能开放但服务未响应 HTTP
            try {
                $tcpClient = New-Object System.Net.Sockets.TcpClient
                $tcpClient.Connect("localhost", $port)
                $tcpClient.Close()
                Write-CheckResult $name $true "http://localhost:$port (端口开放)"
            } catch {
                Write-CheckResult $name $false "http://localhost:$port (无响应)"
            }
        }
    }
}

function Show-Recommendations {
    Write-Title "8. 建议操作"

    Write-Host ""
    Write-Host "  根据诊断结果，建议执行以下操作:" -ForegroundColor Yellow
    Write-Host ""

    # 检查 Docker 是否运行
    try {
        $null = docker ps 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  1. 启动 Docker Desktop" -ForegroundColor White
        }
    } catch {}

    # 检查项目目录
    $projectDir = Join-Path $PSScriptRoot "BettaFish-main"
    if (-not (Test-Path $projectDir)) {
        Write-Host "  2. 下载 BettaFish-main 项目源码" -ForegroundColor White
    }

    # 检查环境文件
    $envFile = Join-Path $projectDir ".env"
    if (-not (Test-Path $envFile)) {
        Write-Host "  3. 运行 docker-deploy.bat 配置环境" -ForegroundColor White
    }

    # 检查防火墙
    try {
        $rules = Get-NetFirewallRule -DisplayName "BettaFish*" -ErrorAction SilentlyContinue
        if (-not $rules) {
            Write-Host "  4. 以管理员身份运行脚本以配置防火墙" -ForegroundColor White
        }
    } catch {}

    Write-Host ""
}

# ================================================================
# 主函数
# ================================================================

function Main {
    Clear-Host
    Write-Host ""
    Write-Host "  BettaFish 诊断工具 $SCRIPT_VERSION" -ForegroundColor Cyan
    Write-Host "  自动检测部署环境和运行状态" -ForegroundColor Gray
    Write-Host ""

    Test-Environment
    Test-ProjectFiles
    Test-DockerImages
    Test-DockerContainers
    Test-Ports
    Test-Firewall
    Test-NetworkAccess
    Show-Recommendations

    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  诊断完成" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
}

# ================================================================
# 脚本入口
# ================================================================

Main
Read-Host "按回车键退出"
