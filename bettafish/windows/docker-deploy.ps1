#Requires -Version 5.1

<#
.SYNOPSIS
    BettaFish Docker 一键部署脚本 - Windows PowerShell 版本

.DESCRIPTION
    自动化部署 BettaFish 舆情分析系统到 Windows 环境
    功能与 Linux Bash 版本完全一致，针对 Windows 优化

.NOTES
    版本: v3.8.3-windows
    作者: LIONCC.AI
    日期: 2025-11-15

.LINK
    https://github.com/your-repo/BettaFish-Deployment-Kit
#>

# ================================================================
# 全局变量和配置
# ================================================================

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"  # 加快 Invoke-WebRequest 速度

# 脚本版本
$SCRIPT_VERSION = "v3.8.3-windows"

# 脚本目录
$SCRIPT_DIR = $PSScriptRoot
$PROJECT_DIR = Join-Path $SCRIPT_DIR "BettaFish-main"

# 端口配置
$DEFAULT_PORT = 5000
$PORT_RANGE = 5001..5010

# 日志目录
$LOG_DIR = Join-Path $SCRIPT_DIR "logs"
$BACKUP_DIR = Join-Path $SCRIPT_DIR "backups"

# 创建必要的目录
if (-not (Test-Path $LOG_DIR)) {
    New-Item -ItemType Directory -Path $LOG_DIR -Force | Out-Null
}
if (-not (Test-Path $BACKUP_DIR)) {
    New-Item -ItemType Directory -Path $BACKUP_DIR -Force | Out-Null
}

# 日志文件
$LOG_FILE = Join-Path $LOG_DIR "deploy_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# ================================================================
# 辅助函数 - 彩色输出
# ================================================================

function Write-ColorOutput {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [ValidateSet('Black', 'DarkBlue', 'DarkGreen', 'DarkCyan', 'DarkRed', 'DarkMagenta',
                     'DarkYellow', 'Gray', 'DarkGray', 'Blue', 'Green', 'Cyan', 'Red',
                     'Magenta', 'Yellow', 'White')]
        [string]$Color = 'White',

        [Parameter(Mandatory=$false)]
        [switch]$NoNewline
    )

    $params = @{
        Object = $Message
        ForegroundColor = $Color
    }

    if ($NoNewline) {
        $params.Add('NoNewline', $true)
    }

    Write-Host @params

    # 同时写入日志文件
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "$timestamp - $Message" | Out-File -FilePath $LOG_FILE -Append -Encoding UTF8
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "ℹ️  $Message" -Color Cyan
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "✅ $Message" -Color Green
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "⚠️  $Message" -Color Yellow
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "❌ $Message" -Color Red
}

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -Color Cyan
    Write-ColorOutput "▶ $Message" -Color Cyan
    Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -Color Cyan
    Write-Host ""
}

# ================================================================
# Logo 和欢迎信息
# ================================================================

function Show-Logo {
    Clear-Host
    Write-Host ""
    Write-ColorOutput "  _      ___ ___  _   _  ____ ____       _    ___ " -Color Cyan
    Write-ColorOutput " | |    |_ _/ _ \| \ | |/ ___/ ___|     / \  |_ _|" -Color Cyan
    Write-ColorOutput " | |     | | | | |  \| | |  | |        / _ \  | | " -Color Cyan
    Write-ColorOutput " | |___  | | |_| | |\  | |__| |___  _ / ___ \ | | " -Color Cyan
    Write-ColorOutput " |_____||___\___/|_| \_|\____\____|(_)_/   \_\___|" -Color Cyan
    Write-Host ""
    Write-ColorOutput "       🐟 BettaFish Docker 一键部署" -Color Green
    Write-ColorOutput "        Windows 版本 $SCRIPT_VERSION" -Color Gray
    Write-ColorOutput "        Powered by LIONCC.AI - 2025" -Color Gray
    Write-Host ""
    Write-Host ""
}

# ================================================================
# 权限检查
# ================================================================

function Test-Administrator {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Request-AdminPrivilege {
    if (-not (Test-Administrator)) {
        Write-Warning "此脚本需要管理员权限才能配置防火墙和系统设置"
        Write-Info "正在请求管理员权限..."
        Write-Host ""

        $arguments = "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`""

        try {
            Start-Process powershell -Verb RunAs -ArgumentList $arguments
            exit
        } catch {
            Write-Error "无法获取管理员权限: $_"
            Write-Warning "请右键点击脚本选择 '以管理员身份运行'"
            Read-Host "按回车键退出"
            exit 1
        }
    }
}

# ================================================================
# 环境检测函数
# ================================================================

function Test-PowerShellVersion {
    $version = $PSVersionTable.PSVersion
    Write-Info "PowerShell 版本: $($version.Major).$($version.Minor)"

    if ($version.Major -lt 5) {
        Write-Error "需要 PowerShell 5.1 或更高版本"
        Write-Info "当前版本: $($version.Major).$($version.Minor)"
        Write-Info "请升级 PowerShell: https://aka.ms/powershell"
        return $false
    }

    return $true
}

function Test-DockerDesktop {
    Write-Info "检测 Docker Desktop..."

    # 检查 docker 命令是否可用
    try {
        $dockerVersion = docker --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Docker 已安装: $dockerVersion"
            return $true
        }
    } catch {
        # Docker 命令不可用
    }

    Write-Error "Docker Desktop 未安装或未添加到 PATH"
    Write-Host ""
    Write-Info "请先安装 Docker Desktop:"
    Write-Info "  下载地址: https://www.docker.com/products/docker-desktop"
    Write-Host ""
    Write-Info "安装步骤:"
    Write-Info "  1. 下载 Docker Desktop for Windows"
    Write-Info "  2. 运行安装程序"
    Write-Info "  3. 重启计算机"
    Write-Info "  4. 启动 Docker Desktop"
    Write-Host ""

    return $false
}

function Test-DockerRunning {
    Write-Info "检测 Docker 服务状态..."

    try {
        $null = docker ps 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Docker 服务运行正常"
            return $true
        }
    } catch {
        # Docker 未运行
    }

    Write-Warning "Docker Desktop 未运行"
    Write-Host ""

    # 询问用户是否已手动启动
    Write-Host "请选择操作:" -ForegroundColor Cyan
    Write-Host "  1. 我已经手动启动了 Docker Desktop，继续检测" -ForegroundColor White
    Write-Host "  2. 让脚本自动启动 Docker Desktop" -ForegroundColor White
    Write-Host "  3. 退出脚本，稍后重试" -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "请输入选项 (1/2/3)"

    if ($choice -eq "1") {
        # 用户已手动启动，重新检测
        Write-Info "正在检测 Docker 服务..."
        Write-Host ""

        $timeout = 60
        $elapsed = 0

        while ($elapsed -lt $timeout) {
            try {
                $null = docker ps 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "Docker Desktop 已就绪"
                    return $true
                }
            } catch {
                # 继续等待
            }

            $elapsed += 5
            Write-Host "等待 Docker 就绪... ($elapsed 秒)" -ForegroundColor Gray
            Start-Sleep -Seconds 5
        }

        Write-Host ""
        Write-Error "Docker Desktop 仍未就绪"
        Write-Info "请确保 Docker Desktop 右下角图标显示为绿色"
        Write-Info "然后重新运行此脚本"
        return $false

    } elseif ($choice -eq "2") {
        # 自动启动
        Write-Info "正在尝试启动 Docker Desktop..."

        $dockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
        if (Test-Path $dockerPath) {
            Start-Process $dockerPath

            Write-Info "等待 Docker Desktop 启动（约 30-60 秒）..."
            Write-Info "提示: 你可以在右下角看到 Docker 图标"
            Write-Host ""

            $timeout = 90
            $elapsed = 0

            while ($elapsed -lt $timeout) {
                Start-Sleep -Seconds 5
                $elapsed += 5

                try {
                    $null = docker ps 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host ""
                        Write-Success "Docker Desktop 已启动"
                        return $true
                    }
                } catch {
                    # 继续等待
                }

                # 显示进度
                $progress = [math]::Min(100, [int](($elapsed / $timeout) * 100))
                Write-Host "`r等待中... $elapsed 秒 / $timeout 秒 [$progress%]" -NoNewline -ForegroundColor Yellow
            }

            Write-Host ""
            Write-Host ""
            Write-Error "Docker Desktop 启动超时"
            Write-Info "可能原因："
            Write-Info "  1. Docker Desktop 启动时间较长（尤其是首次启动）"
            Write-Info "  2. 系统资源不足"
            Write-Info "  3. WSL2 未正确配置"
            Write-Host ""
            Write-Info "建议："
            Write-Info "  1. 手动启动 Docker Desktop 并等待完全就绪"
            Write-Info "  2. 检查右下角 Docker 图标是否为绿色"
            Write-Info "  3. 然后重新运行此脚本"
            return $false
        } else {
            Write-Error "找不到 Docker Desktop 可执行文件"
            Write-Info "预期路径: $dockerPath"
            Write-Info "请检查 Docker Desktop 是否正确安装"
            return $false
        }

    } else {
        # 用户选择退出
        Write-Info "脚本已退出"
        Write-Info "请手动启动 Docker Desktop 后重新运行"
        return $false
    }
}

function Test-NetworkConnection {
    Write-Info "检测网络连接..."

    try {
        $result = Test-Connection -ComputerName "www.google.com" -Count 1 -Quiet -ErrorAction SilentlyContinue
        if ($result) {
            Write-Success "网络连接正常"
            return $true
        }
    } catch {
        # 网络不可达
    }

    # 尝试国内地址
    try {
        $result = Test-Connection -ComputerName "www.baidu.com" -Count 1 -Quiet -ErrorAction SilentlyContinue
        if ($result) {
            Write-Success "网络连接正常（国内网络）"
            return $true
        }
    } catch {
        # 网络不可达
    }

    Write-Warning "网络连接异常"
    Write-Info "请检查网络设置"
    return $false
}

# ================================================================
# 项目源码检测函数
# ================================================================

function Get-ProjectSource {
    Write-Info "查找 BettaFish 项目源码..."

    $possiblePaths = @(
        (Join-Path $SCRIPT_DIR "BettaFish-main"),
        (Join-Path (Get-Location) "BettaFish-main")
    )

    foreach ($path in $possiblePaths) {
        $composePath = Join-Path $path "docker-compose.yml"
        if ((Test-Path $path) -and (Test-Path $composePath)) {
            $script:PROJECT_DIR = $path
            Write-Success "找到项目目录: $path"
            return $true
        }
    }

    Write-Error "未找到 BettaFish-main 目录或 docker-compose.yml 文件"
    Write-Info "请确保此脚本与 BettaFish-main 目录在同一位置"
    return $false
}

# ================================================================
# API 配置函数
# ================================================================

function Get-APIConfiguration {
    Write-Info "配置 API 密钥"
    Write-Host ""

    $apiKeys = @{}

    # OpenAI API Key
    Write-Host "请输入 OpenAI API Key:" -NoNewline
    Write-Host " (必填)" -ForegroundColor Yellow
    $openaiKey = Read-Host "OpenAI API Key"

    while ([string]::IsNullOrWhiteSpace($openaiKey)) {
        Write-Warning "OpenAI API Key 不能为空"
        $openaiKey = Read-Host "OpenAI API Key"
    }

    $apiKeys['OPENAI_API_KEY'] = $openaiKey.Trim()

    # Firecrawl API Key (可选)
    Write-Host ""
    Write-Host "请输入 Firecrawl API Key:" -NoNewline
    Write-Host " (可选，直接回车跳过)" -ForegroundColor Gray
    $firecrawlKey = Read-Host "Firecrawl API Key"

    if (-not [string]::IsNullOrWhiteSpace($firecrawlKey)) {
        $apiKeys['FIRECRAWL_API_KEY'] = $firecrawlKey.Trim()
    } else {
        $apiKeys['FIRECRAWL_API_KEY'] = ""
    }

    Write-Host ""
    Write-Success "API 配置完成"

    return $apiKeys
}

# ================================================================
# 环境文件生成函数
# ================================================================

function Generate-EnvFile {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$APIKeys
    )

    $envFile = Join-Path $PROJECT_DIR ".env"

    Write-Info "生成环境配置文件: .env"

    $envContent = @"
# BettaFish 环境配置文件
# 自动生成于: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

# OpenAI API Configuration
OPENAI_API_KEY=$($APIKeys['OPENAI_API_KEY'])

# Firecrawl API Configuration
FIRECRAWL_API_KEY=$($APIKeys['FIRECRAWL_API_KEY'])

# Database Configuration
POSTGRES_USER=bettafish
POSTGRES_PASSWORD=bettafish_secure_2024
POSTGRES_DB=bettafish_db
POSTGRES_HOST=postgres
POSTGRES_PORT=5432

# Application Configuration
APP_ENV=production
DEBUG=false
"@

    try {
        $envContent | Out-File -FilePath $envFile -Encoding UTF8 -Force
        Write-Success "环境文件生成成功"
        return $true
    } catch {
        Write-Error "环境文件生成失败: $_"
        return $false
    }
}

# ================================================================
# Docker 镜像管理函数
# ================================================================

function Manage-DockerImages {
    Write-Info "检查 Docker 镜像..."

    # 检查 postgres:15 镜像
    try {
        $postgresExists = docker images postgres:15 --format "{{.Repository}}" 2>$null

        if ($postgresExists -eq "postgres") {
            Write-Success "PostgreSQL 镜像已存在"
        } else {
            Write-Info "正在拉取 PostgreSQL 镜像..."
            docker pull postgres:15 2>&1 | Out-Null

            if ($LASTEXITCODE -ne 0) {
                Write-Warning "PostgreSQL 从 Docker Hub 拉取失败"
                Write-Info "尝试使用国内镜像加速源..."
                Write-Host ""

                # 尝试使用 DaoCloud 镜像源
                docker pull docker.m.daocloud.io/postgres:15 2>&1 | Out-Null

                if ($LASTEXITCODE -eq 0) {
                    Write-Success "PostgreSQL 镜像拉取成功 (使用 DaoCloud 加速)"

                    # 重新标记镜像
                    docker tag docker.m.daocloud.io/postgres:15 postgres:15
                    docker rmi docker.m.daocloud.io/postgres:15 2>$null | Out-Null

                    Write-Info "镜像已重新标记为 postgres:15"
                } else {
                    # 尝试使用南京大学镜像源
                    Write-Info "尝试使用南京大学镜像源..."
                    docker pull docker.nju.edu.cn/postgres:15 2>&1 | Out-Null

                    if ($LASTEXITCODE -eq 0) {
                        Write-Success "PostgreSQL 镜像拉取成功 (使用南京大学镜像)"

                        # 重新标记镜像
                        docker tag docker.nju.edu.cn/postgres:15 postgres:15
                        docker rmi docker.nju.edu.cn/postgres:15 2>$null | Out-Null

                        Write-Info "镜像已重新标记为 postgres:15"
                    } else {
                        Write-Error "PostgreSQL 镜像拉取失败（所有源均失败）"
                        Write-Host ""
                        Write-Info "建议："
                        Write-Info "  1. 配置 Docker Desktop 镜像加速器"
                        Write-Info "  2. 检查网络连接"
                        Write-Info "  3. 手动执行: docker pull postgres:15"
                        return $false
                    }
                }
            } else {
                Write-Success "PostgreSQL 镜像拉取成功"
            }
        }
    } catch {
        Write-Warning "无法检查 PostgreSQL 镜像"
    }

    # 检查 BettaFish 镜像
    Write-Info "检查 BettaFish 镜像..."

    $imageName = "ghcr.io/jasonz93/bettafish:latest"

    try {
        $bettafishExists = docker images $imageName --format "{{.Repository}}" 2>$null

        if ($bettafishExists) {
            Write-Success "BettaFish 镜像已存在"

            # 询问是否更新
            Write-Host ""
            $update = Read-Host "是否拉取最新镜像? [y/N]"

            if ($update -eq 'y' -or $update -eq 'Y') {
                Write-Info "正在拉取最新镜像..."
                docker pull $imageName

                if ($LASTEXITCODE -eq 0) {
                    Write-Success "镜像更新成功"
                } else {
                    Write-Warning "镜像更新失败，将使用本地镜像"
                }
            }
        } else {
            Write-Info "正在拉取 BettaFish 镜像..."
            docker pull $imageName

            if ($LASTEXITCODE -ne 0) {
                Write-Error "BettaFish 镜像拉取失败"
                return $false
            }

            Write-Success "BettaFish 镜像拉取成功"
        }
    } catch {
        Write-Error "镜像检查失败: $_"
        return $false
    }

    Write-Host ""
    return $true
}

# ================================================================
# 服务部署函数
# ================================================================

function Deploy-Services {
    Write-Info "启动 Docker 服务..."

    # 切换到项目目录
    Push-Location $PROJECT_DIR

    try {
        # 读取配置的端口
        $configuredPort = $null
        $composeContent = Get-Content "docker-compose.yml" -Raw

        if ($composeContent -match '- "(\d+):5000"') {
            $configuredPort = $Matches[1]
            Write-Info "检测到已配置端口: $configuredPort"
        } else {
            $configuredPort = $DEFAULT_PORT
        }

        # 检查端口是否可用
        $portAvailable = Test-PortAvailable -Port $configuredPort

        if (-not $portAvailable) {
            Write-Warning "端口 $configuredPort 已被占用"
            Write-Info "正在查找可用端口..."

            $foundPort = $null
            foreach ($port in $PORT_RANGE) {
                if (Test-PortAvailable -Port $port) {
                    $foundPort = $port
                    Write-Success "找到可用端口: $foundPort"
                    break
                }
            }

            if (-not $foundPort) {
                Write-Error "端口范围 $($PORT_RANGE[0])-$($PORT_RANGE[-1]) 全部被占用"
                Pop-Location
                return $null
            }

            # 更新 docker-compose.yml 端口配置
            Write-Info "更新端口配置: $configuredPort → $foundPort"
            $composeContent = $composeContent -replace "- `"$configuredPort`:5000`"", "- `"$foundPort`:5000`""
            $composeContent | Out-File -FilePath "docker-compose.yml" -Encoding UTF8 -Force

            $configuredPort = $foundPort
        } else {
            Write-Success "端口 $configuredPort 可用"
        }

        # 启动服务
        Write-Info "执行 docker-compose up -d..."
        Write-Host ""

        docker-compose up -d

        if ($LASTEXITCODE -ne 0) {
            Write-Error "服务启动失败"
            Pop-Location
            return $null
        }

        Write-Host ""
        Write-Success "服务启动成功"

        # 等待服务就绪
        Write-Info "等待服务就绪（约 10-15 秒）..."
        Start-Sleep -Seconds 15

        Pop-Location
        return $configuredPort

    } catch {
        Write-Error "服务部署失败: $_"
        Pop-Location
        return $null
    }
}

# ================================================================
# 端口检测函数
# ================================================================

function Test-PortAvailable {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Port
    )

    try {
        $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, $Port)
        $listener.Start()
        $listener.Stop()
        return $true
    } catch {
        return $false
    }
}

# ================================================================
# 网络配置函数
# ================================================================

function Configure-Network {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Port
    )

    # 配置防火墙
    Write-Info "配置 Windows 防火墙..."

    try {
        # 删除旧规则（如果存在）
        $existingRules = Get-NetFirewallRule -DisplayName "BettaFish*" -ErrorAction SilentlyContinue
        if ($existingRules) {
            Remove-NetFirewallRule -DisplayName "BettaFish*" -ErrorAction SilentlyContinue
        }

        # 添加主服务端口规则
        New-NetFirewallRule -DisplayName "BettaFish Main Service" `
                             -Direction Inbound `
                             -Protocol TCP `
                             -LocalPort $Port `
                             -Action Allow `
                             -ErrorAction Stop | Out-Null

        Write-Success "防火墙端口 $Port 已开放"

        # 添加 Streamlit 端口规则
        New-NetFirewallRule -DisplayName "BettaFish Streamlit Services" `
                             -Direction Inbound `
                             -Protocol TCP `
                             -LocalPort 8501,8502,8503 `
                             -Action Allow `
                             -ErrorAction Stop | Out-Null

        Write-Success "防火墙端口 8501-8503 已开放"

    } catch {
        Write-Warning "防火墙配置失败: $_"
        Write-Info "请手动在 Windows 防火墙中开放端口 $Port 和 8501-8503"
    }

    # 获取本机 IP
    Write-Host ""
    Write-Info "检测网络地址..."

    $localIP = Get-NetIPAddress -AddressFamily IPv4 |
               Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } |
               Select-Object -First 1 -ExpandProperty IPAddress

    # 尝试获取公网 IP
    $publicIP = $null
    try {
        # 使用 ipinfo.io (返回纯文本 IP)
        $publicIP = (Invoke-WebRequest -Uri "https://ipinfo.io/ip" -TimeoutSec 5 -UseBasicParsing).Content.Trim()
    } catch {
        try {
            # 备用: api.ipify.org
            $publicIP = (Invoke-WebRequest -Uri "https://api.ipify.org" -TimeoutSec 5 -UseBasicParsing).Content.Trim()
        } catch {
            # 无法获取公网 IP
        }
    }

    # 验证 IP 格式
    if ($publicIP -and $publicIP -notmatch '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
        $publicIP = $null
    }

    # 显示访问地址
    Write-Host ""
    Write-Host ""
    Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -Color Green
    Write-ColorOutput "  访问地址" -Color Green
    Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -Color Green
    Write-Host ""

    Write-ColorOutput "  本地访问:" -Color Cyan
    Write-ColorOutput "    http://localhost:$Port" -Color White
    Write-Host ""

    if ($localIP) {
        Write-ColorOutput "  局域网访问:" -Color Cyan
        Write-ColorOutput "    http://${localIP}:$Port" -Color White
        Write-Host ""
    }

    if ($publicIP) {
        Write-ColorOutput "  公网访问:" -Color Cyan
        Write-ColorOutput "    http://${publicIP}:$Port" -Color Yellow
        Write-Host ""
        Write-ColorOutput "  ⚠️  如果无法访问公网地址，请检查:" -Color Yellow
        Write-ColorOutput "    1. 云服务器安全组配置" -Color Gray
        Write-ColorOutput "    2. 路由器端口转发" -Color Gray
        Write-ColorOutput "    3. ISP 是否允许公网访问" -Color Gray
        Write-Host ""
    }

    Write-ColorOutput "  Streamlit 服务:" -Color Cyan
    Write-ColorOutput "    Insight Engine:  http://localhost:8501" -Color White
    Write-ColorOutput "    Media Engine:    http://localhost:8502" -Color White
    Write-ColorOutput "    Query Engine:    http://localhost:8503" -Color White
    Write-Host ""

    Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -Color Green
    Write-Host ""

    # 显示管理命令
    Write-ColorOutput "  常用管理命令:" -Color Cyan
    Write-Host ""
    Write-ColorOutput "    查看服务状态:" -Color Gray
    Write-ColorOutput "      docker-compose ps" -Color White
    Write-Host ""
    Write-ColorOutput "    查看服务日志:" -Color Gray
    Write-ColorOutput "      docker-compose logs -f" -Color White
    Write-Host ""
    Write-ColorOutput "    停止服务:" -Color Gray
    Write-ColorOutput "      docker-compose down" -Color White
    Write-Host ""
    Write-ColorOutput "    重启服务:" -Color Gray
    Write-ColorOutput "      docker-compose restart" -Color White
    Write-Host ""
}

# ================================================================
# 主函数
# ================================================================

function Main {
    try {
        # 显示 Logo
        Show-Logo

        # 请求管理员权限
        Request-AdminPrivilege

        # 步骤 1: 环境检测
        Write-Step "步骤 1/7: 环境检测与依赖检查"

        if (-not (Test-PowerShellVersion)) {
            Read-Host "按回车键退出"
            exit 1
        }

        if (-not (Test-DockerDesktop)) {
            Read-Host "按回车键退出"
            exit 1
        }

        if (-not (Test-DockerRunning)) {
            Read-Host "按回车键退出"
            exit 1
        }

        Test-NetworkConnection

        Write-Host ""
        Write-Success "环境检测完成"
        Write-Host ""

        # 步骤 2: 项目检测
        Write-Step "步骤 2/7: 检测 BettaFish 项目源码"

        if (-not (Get-ProjectSource)) {
            Read-Host "按回车键退出"
            exit 1
        }

        # 步骤 3: API 配置
        Write-Step "步骤 3/7: 配置 API 密钥"

        $apiKeys = Get-APIConfiguration
        if (-not $apiKeys) {
            Read-Host "按回车键退出"
            exit 1
        }

        # 步骤 4: 生成环境文件
        Write-Step "步骤 4/7: 生成环境配置文件"

        if (-not (Generate-EnvFile -APIKeys $apiKeys)) {
            Read-Host "按回车键退出"
            exit 1
        }

        # 步骤 5: 镜像管理
        Write-Step "步骤 5/7: Docker 镜像管理"

        if (-not (Manage-DockerImages)) {
            Read-Host "按回车键退出"
            exit 1
        }

        # 步骤 6: 服务部署
        Write-Step "步骤 6/7: 启动 Docker 服务"

        $port = Deploy-Services
        if (-not $port) {
            Read-Host "按回车键退出"
            exit 1
        }

        # 步骤 7: 网络配置
        Write-Step "步骤 7/7: 网络配置与完成"

        Configure-Network -Port $port

        Write-Host ""
        Write-Host ""
        Write-Success "=========================================="
        Write-Success "   BettaFish 部署完成！"
        Write-Success "=========================================="
        Write-Host ""

        Read-Host "按回车键退出"

    } catch {
        Write-Error "发生错误: $_"
        Write-Host ""
        Write-Info "错误详情:"
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host $_.ScriptStackTrace -ForegroundColor Gray
        Write-Host ""
        Read-Host "按回车键退出"
        exit 1
    }
}

# ================================================================
# 脚本入口
# ================================================================

Main
