#Requires -Version 5.1

<#
.SYNOPSIS
    BettaFish 智能修复工具 - Windows 版本
.DESCRIPTION
    自动检测并修复 BettaFish 部署中的常见问题
    - 文件编码问题（UTF-8 BOM）
    - Docker 服务问题
    - 端口占用问题
    - 配置文件问题
    - 镜像源问题
    - 容器状态问题
.AUTHOR
    LIONCC.AI
.VERSION
    2.0
#>

param(
    [switch]$EncodingOnly,  # 只修复编码问题
    [switch]$SkipEncoding,  # 跳过编码修复
    [switch]$QuickFix       # 快速修复（仅编码+Docker服务）
)

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# ================================================================
# 全局变量
# ================================================================

# 脚本在 scripts/ 目录中
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
# 工作目录是上一级（Windows/）
$WORK_DIR = Split-Path -Parent $SCRIPT_DIR
$PROJECT_DIR = Join-Path $WORK_DIR "BettaFish-main"
$LOG_DIR = Join-Path $WORK_DIR "logs"
$BACKUP_DIR = Join-Path $WORK_DIR "backups"

# 问题统计
$script:IssuesFound = 0
$script:IssuesFixed = 0
$script:IssuesFailed = 0
$script:EncodingFixed = 0

# ================================================================
# 辅助函数
# ================================================================

function Write-ColorText {
    param(
        [string]$Text,
        [string]$Color = "White"
    )
    Write-Host $Text -ForegroundColor $Color
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-ErrorMsg {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-SectionHeader {
    param([string]$Title)
    Write-Host ""
    Write-ColorText "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Cyan"
    Write-ColorText "▶ $Title" "Cyan"
    Write-ColorText "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Cyan"
    Write-Host ""
}

function Write-FixResult {
    param(
        [bool]$Success,
        [string]$Message
    )
    if ($Success) {
        Write-Success $Message
        $script:IssuesFixed++
    } else {
        Write-ErrorMsg $Message
        $script:IssuesFailed++
    }
}

# ================================================================
# 检测与修复函数
# ================================================================

# 0. 检查并修复文件编码（UTF-8 BOM）
function Test-And-Fix-Encoding {
    Write-SectionHeader "检查文件编码"

    # PowerShell 文件列表
    $psFiles = @(
        "menu.ps1",
        "docker-deploy.ps1",
        "diagnose.ps1",
        "download-project.ps1",
        "fix-docker-mirrors.ps1",
        "fix-all.ps1"
    )

    Write-Info "检测 PowerShell 脚本的编码格式..."
    Write-Info "Windows PowerShell 需要 UTF-8 with BOM 才能正确显示中文"
    Write-Host ""

    $hasEncodingIssue = $false
    $fixedCount = 0

    foreach ($fileName in $psFiles) {
        $filePath = Join-Path $SCRIPT_DIR $fileName

        if (-not (Test-Path $filePath)) {
            Write-Host "[SKIP] $fileName - 文件不存在" -ForegroundColor Gray
            continue
        }

        try {
            # 读取文件字节检查 BOM
            $bytes = [System.IO.File]::ReadAllBytes($filePath)

            # 检查是否有 UTF-8 BOM (EF BB BF)
            $hasBOM = ($bytes.Length -ge 3) -and
                      ($bytes[0] -eq 0xEF) -and
                      ($bytes[1] -eq 0xBB) -and
                      ($bytes[2] -eq 0xBF)

            if ($hasBOM) {
                Write-Success "$fileName - 编码正确 (UTF-8 with BOM)"
            } else {
                Write-Warning "$fileName - 缺少 BOM 标记"
                $hasEncodingIssue = $true
                $script:IssuesFound++

                # 询问是否修复
                Write-Info "  正在修复编码..."

                # 读取内容（假设是 UTF-8 without BOM）
                $content = [System.IO.File]::ReadAllText($filePath, [System.Text.UTF8Encoding]::new($false))

                # 创建备份
                $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                $backupPath = "$filePath.backup_encoding_$timestamp"
                Copy-Item -Path $filePath -Destination $backupPath -Force

                # 写入 UTF-8 with BOM
                $utf8BOM = [System.Text.UTF8Encoding]::new($true)
                [System.IO.File]::WriteAllText($filePath, $content, $utf8BOM)

                # 验证
                $newBytes = [System.IO.File]::ReadAllBytes($filePath)
                $verifyBOM = ($newBytes.Length -ge 3) -and
                             ($newBytes[0] -eq 0xEF) -and
                             ($newBytes[1] -eq 0xBB) -and
                             ($newBytes[2] -eq 0xBF)

                if ($verifyBOM) {
                    Write-FixResult $true "$fileName - 已转换为 UTF-8 with BOM"
                    $script:EncodingFixed++
                    $fixedCount++
                } else {
                    # 恢复备份
                    Copy-Item -Path $backupPath -Destination $filePath -Force
                    Write-FixResult $false "$fileName - 编码修复失败，已恢复"
                }
            }
        } catch {
            Write-ErrorMsg "$fileName - 处理出错: $_"
            $script:IssuesFailed++
        }
    }

    Write-Host ""
    if ($fixedCount -gt 0) {
        Write-Success "已修复 $fixedCount 个文件的编码问题"
        Write-Info "现在可以正常运行 menu.bat 和其他脚本了"
    } elseif (-not $hasEncodingIssue) {
        Write-Success "所有 PowerShell 脚本编码正确"
    }

    return (-not $hasEncodingIssue) -or ($fixedCount -gt 0)
}

# 1. 检查并修复 Docker 服务
function Test-And-Fix-DockerService {
    Write-SectionHeader "检查 Docker 服务"

    try {
        $dockerVersion = docker --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Docker 已安装: $dockerVersion"
        } else {
            throw "Docker 未安装"
        }
    } catch {
        Write-ErrorMsg "Docker 未安装或未添加到 PATH"
        Write-Warning "请访问 https://www.docker.com/products/docker-desktop 下载安装 Docker Desktop"
        $script:IssuesFound++
        return $false
    }

    # 检查 Docker 服务是否运行
    try {
        docker ps >$null 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Docker 服务运行正常"
            return $true
        } else {
            throw "Docker 服务未运行"
        }
    } catch {
        Write-Warning "Docker 服务未运行，尝试启动..."
        $script:IssuesFound++

        # 尝试启动 Docker Desktop
        $dockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
        if (Test-Path $dockerPath) {
            Start-Process $dockerPath
            Write-Info "正在启动 Docker Desktop，请稍候..."

            # 等待 Docker 启动（最多等待 60 秒）
            $timeout = 60
            $elapsed = 0
            $interval = 5

            while ($elapsed -lt $timeout) {
                Start-Sleep -Seconds $interval
                $elapsed += $interval

                Write-Host "." -NoNewline

                docker ps >$null 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Host ""
                    Write-FixResult $true "Docker 服务已启动"
                    return $true
                }
            }

            Write-Host ""
            Write-FixResult $false "Docker 服务启动超时，请手动启动 Docker Desktop"
            return $false
        } else {
            Write-FixResult $false "未找到 Docker Desktop，请手动安装"
            return $false
        }
    }
}

# 2. 检查并修复端口占用
function Test-And-Fix-PortConflicts {
    Write-SectionHeader "检查端口占用"

    $ports = @(5001, 8501, 8502, 8503)
    $hasConflict = $false

    foreach ($port in $ports) {
        $connection = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue

        if ($connection) {
            $hasConflict = $true
            $script:IssuesFound++

            $process = Get-Process -Id $connection.OwningProcess -ErrorAction SilentlyContinue
            if ($process) {
                Write-Warning "端口 $port 被占用: $($process.ProcessName) (PID: $($process.Id))"

                # 询问是否终止进程
                $answer = Read-Host "是否终止该进程? [y/N]"
                if ($answer -eq 'y' -or $answer -eq 'Y') {
                    try {
                        Stop-Process -Id $process.Id -Force
                        Write-FixResult $true "已终止进程 $($process.ProcessName)"
                    } catch {
                        Write-FixResult $false "无法终止进程: $_"
                    }
                } else {
                    Write-Info "跳过端口 $port 的修复"
                    $script:IssuesFound--
                }
            }
        } else {
            Write-Success "端口 $port 可用"
        }
    }

    if (-not $hasConflict) {
        Write-Success "所有端口均可用"
    }

    return -not $hasConflict
}

# 3. 检查并修复 BettaFish 项目目录
function Test-And-Fix-ProjectDirectory {
    Write-SectionHeader "检查项目目录"

    if (Test-Path $PROJECT_DIR) {
        Write-Success "BettaFish 项目目录存在"

        # 检查关键文件
        $criticalFiles = @(
            "docker-compose.yml",
            "Dockerfile"
        )

        $allFilesExist = $true
        foreach ($file in $criticalFiles) {
            $filePath = Join-Path $PROJECT_DIR $file
            if (-not (Test-Path $filePath)) {
                Write-Warning "缺少文件: $file"
                $allFilesExist = $false
            }
        }

        if ($allFilesExist) {
            Write-Success "关键文件完整"
            return $true
        } else {
            Write-Warning "项目文件不完整"
            $script:IssuesFound++

            $answer = Read-Host "是否重新下载项目? [y/N]"
            if ($answer -eq 'y' -or $answer -eq 'Y') {
                try {
                    # 备份现有目录
                    if (Test-Path $PROJECT_DIR) {
                        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                        $backupPath = "$PROJECT_DIR`_backup_$timestamp"
                        Move-Item $PROJECT_DIR $backupPath
                        Write-Info "已备份到: $backupPath"
                    }

                    # 调用下载脚本
                    $downloadScript = Join-Path $SCRIPT_DIR "download-project.ps1"
                    if (Test-Path $downloadScript) {
                        & $downloadScript
                        if ($LASTEXITCODE -eq 0) {
                            Write-FixResult $true "项目重新下载成功"
                            return $true
                        }
                    }

                    Write-FixResult $false "项目下载失败"
                    return $false
                } catch {
                    Write-FixResult $false "项目下载出错: $_"
                    return $false
                }
            }
        }
    } else {
        Write-Warning "BettaFish 项目目录不存在"
        $script:IssuesFound++

        $answer = Read-Host "是否下载项目? [Y/n]"
        if ($answer -ne 'n' -and $answer -ne 'N') {
            try {
                $downloadScript = Join-Path $SCRIPT_DIR "download-project.ps1"
                if (Test-Path $downloadScript) {
                    & $downloadScript
                    if ($LASTEXITCODE -eq 0) {
                        Write-FixResult $true "项目下载成功"
                        return $true
                    }
                }

                Write-FixResult $false "项目下载失败"
                return $false
            } catch {
                Write-FixResult $false "项目下载出错: $_"
                return $false
            }
        }
    }

    return $false
}

# 4. 检查并修复配置文件
function Test-And-Fix-Configuration {
    Write-SectionHeader "检查配置文件"

    $envFile = Join-Path $PROJECT_DIR ".env"

    if (-not (Test-Path $PROJECT_DIR)) {
        Write-Warning "项目目录不存在，跳过配置检查"
        return $false
    }

    if (Test-Path $envFile) {
        Write-Success "配置文件存在: .env"

        # 读取并验证配置
        $envContent = Get-Content $envFile -Raw

        # 检查必需的配置项
        $requiredKeys = @(
            "API_KEY",
            "POSTGRES_USER",
            "POSTGRES_PASSWORD",
            "POSTGRES_DB"
        )

        $missingKeys = @()
        foreach ($key in $requiredKeys) {
            if ($envContent -notmatch "$key\s*=\s*.+") {
                $missingKeys += $key
            }
        }

        if ($missingKeys.Count -eq 0) {
            Write-Success "配置文件完整"
            return $true
        } else {
            Write-Warning "配置文件缺少以下项: $($missingKeys -join ', ')"
            $script:IssuesFound++

            $answer = Read-Host "是否重新配置? [y/N]"
            if ($answer -eq 'y' -or $answer -eq 'Y') {
                # 备份现有配置
                $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                $backupPath = Join-Path $BACKUP_DIR ".env_backup_$timestamp"
                New-Item -ItemType Directory -Force -Path $BACKUP_DIR | Out-Null
                Copy-Item $envFile $backupPath
                Write-Info "已备份配置到: $backupPath"

                # 调用部署脚本重新配置
                Write-Info "请运行 docker-deploy.bat 重新配置"
                Write-FixResult $false "需要手动重新配置"
                return $false
            }
        }
    } else {
        Write-Warning "配置文件不存在"
        $script:IssuesFound++
        Write-Info "请运行 docker-deploy.bat 创建配置"
        return $false
    }

    return $false
}

# 5. 检查并修复 Docker 容器状态
function Test-And-Fix-ContainerStatus {
    Write-SectionHeader "检查容器状态"

    if (-not (Test-Path $PROJECT_DIR)) {
        Write-Warning "项目目录不存在，跳过容器检查"
        return $false
    }

    Push-Location $PROJECT_DIR

    try {
        # 检查是否有运行的容器
        $containers = docker-compose ps -q 2>$null

        if ([string]::IsNullOrEmpty($containers)) {
            Write-Info "没有运行中的容器"
            return $true
        }

        # 获取容器状态
        $psOutput = docker-compose ps 2>$null

        if ($psOutput -match "Exit|Exited") {
            Write-Warning "检测到异常退出的容器"
            $script:IssuesFound++

            Write-Info "容器状态:"
            docker-compose ps

            $answer = Read-Host "是否重启容器? [Y/n]"
            if ($answer -ne 'n' -and $answer -ne 'N') {
                try {
                    Write-Info "正在重启容器..."
                    docker-compose down
                    docker-compose up -d

                    if ($LASTEXITCODE -eq 0) {
                        Write-FixResult $true "容器已重启"

                        # 等待服务启动
                        Write-Info "等待服务启动..."
                        Start-Sleep -Seconds 10

                        docker-compose ps
                        return $true
                    } else {
                        Write-FixResult $false "容器重启失败"
                        return $false
                    }
                } catch {
                    Write-FixResult $false "容器重启出错: $_"
                    return $false
                }
            }
        } else {
            Write-Success "所有容器运行正常"
            docker-compose ps
            return $true
        }
    } finally {
        Pop-Location
    }

    return $false
}

# 6. 检查并修复 Docker 镜像
function Test-And-Fix-DockerImages {
    Write-SectionHeader "检查 Docker 镜像"

    if (-not (Test-Path $PROJECT_DIR)) {
        Write-Warning "项目目录不存在，跳过镜像检查"
        return $false
    }

    Push-Location $PROJECT_DIR

    try {
        # 检查 docker-compose.yml 中的镜像
        $composeFile = Join-Path $PROJECT_DIR "docker-compose.yml"
        if (-not (Test-Path $composeFile)) {
            Write-Warning "docker-compose.yml 不存在"
            return $false
        }

        # 检查主镜像
        $images = docker images --format "{{.Repository}}:{{.Tag}}" | Where-Object { $_ -match "bettafish" }

        if ($images) {
            Write-Success "BettaFish 镜像已存在"
            Write-Info "镜像列表:"
            docker images | Select-String "bettafish"
            return $true
        } else {
            Write-Warning "BettaFish 镜像不存在"
            $script:IssuesFound++

            $answer = Read-Host "是否拉取镜像? [Y/n]"
            if ($answer -ne 'n' -and $answer -ne 'N') {
                try {
                    Write-Info "正在拉取镜像..."
                    docker-compose pull

                    if ($LASTEXITCODE -eq 0) {
                        Write-FixResult $true "镜像拉取成功"
                        return $true
                    } else {
                        Write-FixResult $false "镜像拉取失败"
                        Write-Info "提示: 可以运行 fix-docker-mirrors.bat 配置镜像加速"
                        return $false
                    }
                } catch {
                    Write-FixResult $false "镜像拉取出错: $_"
                    return $false
                }
            }
        }
    } finally {
        Pop-Location
    }

    return $false
}

# 7. 检查磁盘空间
function Test-DiskSpace {
    Write-SectionHeader "检查磁盘空间"

    try {
        $drive = $SCRIPT_DIR.Substring(0, 2)
        $disk = Get-PSDrive -Name $drive.Substring(0, 1) -ErrorAction SilentlyContinue

        if ($disk) {
            $freeGB = [math]::Round($disk.Free / 1GB, 2)

            if ($freeGB -lt 5) {
                Write-Warning "磁盘空间不足: 仅剩 $freeGB GB"
                $script:IssuesFound++
                Write-Info "建议: 清理磁盘空间或运行 docker system prune 清理 Docker 资源"
                return $false
            } elseif ($freeGB -lt 10) {
                Write-Warning "磁盘空间较低: 剩余 $freeGB GB"
                Write-Info "建议: 及时清理磁盘空间"
                return $true
            } else {
                Write-Success "磁盘空间充足: 剩余 $freeGB GB"
                return $true
            }
        }
    } catch {
        Write-Warning "无法检查磁盘空间: $_"
    }

    return $true
}

# 8. 检查网络连接
function Test-NetworkConnectivity {
    Write-SectionHeader "检查网络连接"

    try {
        # 测试 GitHub 连接（用于下载项目）
        $githubTest = Test-Connection -ComputerName "github.com" -Count 1 -Quiet -ErrorAction SilentlyContinue

        if ($githubTest) {
            Write-Success "GitHub 连接正常"
        } else {
            Write-Warning "无法连接到 GitHub"
            Write-Info "提示: 可能影响项目下载"
        }

        # 测试 Docker Hub 连接
        $dockerHubTest = Test-Connection -ComputerName "hub.docker.com" -Count 1 -Quiet -ErrorAction SilentlyContinue

        if ($dockerHubTest) {
            Write-Success "Docker Hub 连接正常"
        } else {
            Write-Warning "无法连接到 Docker Hub"
            Write-Info "提示: 建议配置 Docker 镜像加速，运行 fix-docker-mirrors.bat"
        }

        return $true
    } catch {
        Write-Warning "网络检测出错: $_"
        return $true
    }
}

# 9. 生成诊断报告
function Write-DiagnosticReport {
    Write-SectionHeader "生成诊断报告"

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $reportFile = Join-Path $LOG_DIR "diagnostic_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

    New-Item -ItemType Directory -Force -Path $LOG_DIR | Out-Null

    $report = @"
========================================
BettaFish 诊断报告
========================================

生成时间: $timestamp
脚本目录: $SCRIPT_DIR
项目目录: $PROJECT_DIR

========================================
系统信息
========================================

操作系统: $([System.Environment]::OSVersion.VersionString)
PowerShell 版本: $($PSVersionTable.PSVersion)
用户名: $env:USERNAME
计算机名: $env:COMPUTERNAME

========================================
Docker 信息
========================================

"@

    try {
        $dockerVersion = docker --version 2>$null
        $report += "Docker 版本: $dockerVersion`n"

        $dockerComposeVersion = docker-compose --version 2>$null
        $report += "Docker Compose 版本: $dockerComposeVersion`n"

        $dockerInfo = docker info 2>$null
        if ($dockerInfo) {
            $report += "`nDocker 详细信息:`n"
            $report += $dockerInfo
        }
    } catch {
        $report += "Docker 信息获取失败: $_`n"
    }

    $report += @"

========================================
检测结果
========================================

发现问题: $script:IssuesFound 个
已修复: $script:IssuesFixed 个
修复失败: $script:IssuesFailed 个

========================================
容器状态
========================================

"@

    if (Test-Path $PROJECT_DIR) {
        Push-Location $PROJECT_DIR
        try {
            $containerStatus = docker-compose ps 2>$null
            if ($containerStatus) {
                $report += $containerStatus
            } else {
                $report += "没有运行中的容器`n"
            }
        } catch {
            $report += "无法获取容器状态: $_`n"
        } finally {
            Pop-Location
        }
    } else {
        $report += "项目目录不存在`n"
    }

    $report += "`n========================================"

    # 保存报告
    $report | Out-File -FilePath $reportFile -Encoding UTF8

    Write-Success "诊断报告已保存: $reportFile"

    # 询问是否打开报告
    $answer = Read-Host "是否查看报告? [y/N]"
    if ($answer -eq 'y' -or $answer -eq 'Y') {
        notepad $reportFile
    }
}

# ================================================================
# 主流程
# ================================================================

function Start-FixAll {
    Write-Host ""
    Write-ColorText "========================================" "Cyan"
    Write-ColorText " BettaFish 智能修复工具 v2.0" "Cyan"
    Write-ColorText " Windows 版本" "Cyan"
    Write-ColorText "========================================" "Cyan"
    Write-Host ""
    Write-ColorText "项目作者: LIONCC.AI" "Gray"
    Write-ColorText "官方 API: https://vibecodingapi.ai" "Gray"
    Write-Host ""

    # 显示运行模式
    if ($EncodingOnly) {
        Write-Info "运行模式: 仅修复文件编码问题"
    } elseif ($QuickFix) {
        Write-Info "运行模式: 快速修复（编码 + Docker 服务）"
    } else {
        Write-Info "运行模式: 完整检测与修复"
    }

    Write-Info "本工具将自动检测并修复常见问题："
    Write-Host ""

    if (-not $SkipEncoding) {
        Write-Host "  ✓ 文件编码问题（UTF-8 BOM）" -ForegroundColor Green
    }
    if (-not $EncodingOnly) {
        Write-Host "  ✓ Docker 服务状态" -ForegroundColor Green
        Write-Host "  ✓ 端口占用冲突" -ForegroundColor Green
        Write-Host "  ✓ 磁盘空间" -ForegroundColor Green
        Write-Host "  ✓ 网络连接" -ForegroundColor Green
        Write-Host "  ✓ 项目文件完整性" -ForegroundColor Green
        Write-Host "  ✓ 配置文件" -ForegroundColor Green
        Write-Host "  ✓ Docker 镜像" -ForegroundColor Green
        Write-Host "  ✓ 容器状态" -ForegroundColor Green
    }
    Write-Host ""

    # 确认开始
    $answer = Read-Host "是否开始检测? [Y/n]"
    if ($answer -eq 'n' -or $answer -eq 'N') {
        Write-Info "已取消"
        return
    }

    Write-Host ""
    Write-ColorText "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Yellow"
    Write-ColorText "开始智能检测与修复..." "Yellow"
    Write-ColorText "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Yellow"

    # 1. 首先修复编码问题（如果不跳过）
    if (-not $SkipEncoding) {
        Test-And-Fix-Encoding
    }

    # 2. 如果是仅编码模式，到此结束
    if ($EncodingOnly) {
        Write-Host ""
        Write-ColorText "========================================" "Yellow"
        Write-ColorText "编码修复完成" "Yellow"
        Write-ColorText "========================================" "Yellow"
        Write-Host ""

        if ($script:EncodingFixed -gt 0) {
            Write-Success "已修复 $script:EncodingFixed 个文件的编码问题"
            Write-Info "现在可以正常运行 menu.bat 和其他脚本了"
        } else {
            Write-Success "所有文件编码正确"
        }

        Write-Host ""
        Write-Info "提示:"
        Write-Host "  - 打开菜单: 双击 menu.bat"
        Write-Host "  - 运行部署: 双击 docker-deploy.bat"
        Write-Host ""
        return
    }

    # 3. 执行其他检测与修复
    Test-And-Fix-DockerService

    if (-not $QuickFix) {
        Test-And-Fix-PortConflicts
        Test-DiskSpace
        Test-NetworkConnectivity
        Test-And-Fix-ProjectDirectory
        Test-And-Fix-Configuration
        Test-And-Fix-DockerImages
        Test-And-Fix-ContainerStatus

        # 生成报告
        Write-DiagnosticReport
    }

    # 显示总结
    Write-Host ""
    Write-ColorText "========================================" "Yellow"
    Write-ColorText "修复完成" "Yellow"
    Write-ColorText "========================================" "Yellow"
    Write-Host ""

    if ($script:IssuesFound -eq 0) {
        Write-Success "未发现问题，系统运行正常！"
    } else {
        Write-Info "统计信息:"
        Write-Host "  发现问题: " -NoNewline
        Write-ColorText "$script:IssuesFound 个" "Yellow"
        Write-Host "  已修复: " -NoNewline
        Write-ColorText "$script:IssuesFixed 个" "Green"

        if ($script:EncodingFixed -gt 0) {
            Write-Host "    └─ 编码修复: " -NoNewline
            Write-ColorText "$script:EncodingFixed 个" "Cyan"
        }

        Write-Host "  修复失败: " -NoNewline
        Write-ColorText "$script:IssuesFailed 个" "Red"
        Write-Host ""

        if ($script:IssuesFailed -gt 0) {
            Write-Warning "部分问题未能自动修复，请查看诊断报告"
        } elseif ($script:IssuesFixed -eq $script:IssuesFound) {
            Write-Success "所有问题已成功修复！"
        }
    }

    Write-Host ""
    Write-Info "提示:"
    Write-Host "  - 查看详细报告: logs 目录"
    Write-Host "  - 运行部署: 双击 docker-deploy.bat"
    Write-Host "  - 打开菜单: 双击 menu.bat"
    Write-Host "  - 查看文档: 双击 START.md"
    Write-Host ""
}

# ================================================================
# 启动
# ================================================================

try {
    Start-FixAll
} catch {
    Write-ErrorMsg "发生错误: $_"
    Write-Host $_.ScriptStackTrace
} finally {
    Write-Host ""
    Write-ColorText "按任意键退出..." "Gray"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
