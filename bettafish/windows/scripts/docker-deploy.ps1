#Requires -Version 5.1

<#
.SYNOPSIS
    BettaFish Docker Deployment Script for Windows
.DESCRIPTION
    One-click deployment of BettaFish using Docker Compose
#>

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# ================================================================
# 全局变量
# ================================================================

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_DIR = Join-Path $SCRIPT_DIR "BettaFish-main"

# ================================================================
# 辅助函数
# ================================================================

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

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-StepHeader {
    param(
        [int]$Step,
        [int]$Total,
        [string]$Title
    )
    $percent = [math]::Round(($Step / $Total) * 100)
    $barLength = 50
    $filled = [math]::Round(($percent / 100) * $barLength)
    $empty = $barLength - $filled

    $bar = "[" + ("=" * $filled) + ">" + ("-" * $empty) + "]"

    Write-Host ""
    Write-Host "$bar  $percent%" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "▶ 步骤 $Step/$Total`: $Title" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
}

# ================================================================
# API 密钥验证和格式化
# ================================================================

function Test-APIKeyFormat {
    param(
        [string]$Key,
        [string]$Type
    )

    # 检查是否为空
    if ([string]::IsNullOrWhiteSpace($Key)) {
        return @{
            Valid = $false
            Error = "API Key 不能为空"
        }
    }

    # 去除首尾空格
    $Key = $Key.Trim()

    # 检查是否包含空格
    if ($Key -match '\s') {
        return @{
            Valid = $false
            Error = "API Key 不应包含空格"
        }
    }

    # 检查是否误输入 URL
    if ($Key -match '^https?://') {
        return @{
            Valid = $false
            Error = "请输入 API Key，不是 URL"
        }
    }

    # 检查长度
    if ($Key.Length -lt 10) {
        return @{
            Valid = $false
            Error = "API Key 长度至少需要 10 个字符"
        }
    }

    # 根据类型检查前缀
    switch ($Type) {
        "main" {
            if (-not ($Key -match '^sk-')) {
                return @{
                    Valid = $false
                    Error = "主 API 密钥应该以 'sk-' 开头"
                }
            }
        }
        "tavily" {
            if (-not ($Key -match '^tvly-')) {
                return @{
                    Valid = $false
                    Error = "Tavily API 密钥应该以 'tvly-' 开头"
                }
            }
        }
        "bocha" {
            if (-not ($Key -match '^sk-')) {
                return @{
                    Valid = $false
                    Error = "Bocha API 密钥应该以 'sk-' 开头"
                }
            }
        }
    }

    return @{
        Valid = $true
        Key = $Key
    }
}

function Format-APIKeyDisplay {
    param([string]$Key)

    if ($Key.Length -le 10) {
        return $Key
    }

    $prefix = $Key.Substring(0, 3)
    $suffix = $Key.Substring($Key.Length - 3, 3)

    return "$prefix***$suffix"
}

function Read-APIKey {
    param(
        [string]$Prompt,
        [string]$Name,
        [string]$Type,
        [bool]$Required = $true
    )

    while ($true) {
        Write-Host $Prompt -NoNewline
        if ($Required) {
            Write-Host " [必填]" -ForegroundColor Yellow -NoNewline
        } else {
            Write-Host " [可选]" -ForegroundColor Gray -NoNewline
        }
        Write-Host ": " -NoNewline

        $key = Read-Host

        # 如果是可选的且为空，允许跳过
        if (-not $Required -and [string]::IsNullOrWhiteSpace($key)) {
            return ""
        }

        # 验证格式
        $validation = Test-APIKeyFormat -Key $key -Type $Type

        if ($validation.Valid) {
            return $validation.Key
        } else {
            Write-Warning $validation.Error
            Write-Host ""
        }
    }
}

# ================================================================
# API 配置函数
# ================================================================

function Get-APIConfiguration {
    Write-Info "配置 API 密钥"
    Write-Host ""

    $apiKeys = @{}
    $envFile = Join-Path $PROJECT_DIR ".env"
    $existingKeys = @{}

    # 检查是否已有 .env 文件
    if (Test-Path $envFile) {
        Write-Info "检测到已有配置文件,正在读取..."

        try {
            $envContent = Get-Content $envFile -Encoding UTF8
            foreach ($line in $envContent) {
                if ($line -match '^([^#][^=]+)=(.*)$') {
                    $key = $Matches[1].Trim()
                    $value = $Matches[2].Trim()
                    if ($value) {
                        $existingKeys[$key] = $value
                    }
                }
            }

            if ($existingKeys.Count -gt 0) {
                # 检查关键配置是否存在 - 检查所有7个引擎的密钥
                $engineKeys = @(
                    'INSIGHT_ENGINE_API_KEY',
                    'MEDIA_ENGINE_API_KEY',
                    'MINDSPIDER_API_KEY',
                    'QUERY_ENGINE_API_KEY',
                    'REPORT_ENGINE_API_KEY',
                    'FORUM_HOST_API_KEY',
                    'KEYWORD_OPTIMIZER_API_KEY'
                )

                # 只要有任意一个引擎配置了密钥,就认为有主密钥
                $hasMainKey = $false
                foreach ($key in $engineKeys) {
                    if ($existingKeys.ContainsKey($key) -and $existingKeys[$key]) {
                        $hasMainKey = $true
                        break
                    }
                }

                $hasTavilyKey = $existingKeys.ContainsKey('TAVILY_API_KEY') -and $existingKeys['TAVILY_API_KEY']
                $hasBochaKey = $existingKeys.ContainsKey('BOCHA_WEB_SEARCH_API_KEY') -and $existingKeys['BOCHA_WEB_SEARCH_API_KEY']

                if (-not $hasMainKey) {
                    Write-Warning "检测到配置文件缺少主 API 密钥配置"
                    Write-Host ""
                } elseif (-not $hasTavilyKey) {
                    Write-Warning "检测到配置文件缺少 Tavily API 密钥"
                    Write-Host ""
                } elseif (-not $hasBochaKey) {
                    Write-Warning "检测到配置文件缺少 Bocha API 密钥"
                    Write-Host ""
                }

                Write-Success "已读取现有配置:"
                if ($hasMainKey) {
                    # 从任意已配置的引擎中获取密钥用于显示
                    $displayKey = $null
                    foreach ($key in $engineKeys) {
                        if ($existingKeys.ContainsKey($key) -and $existingKeys[$key]) {
                            $displayKey = $existingKeys[$key]
                            break
                        }
                    }
                    Write-Host "  • 主 API 密钥: $(Format-APIKeyDisplay $displayKey)" -ForegroundColor Gray
                } else {
                    Write-Host "  • 主 API 密钥: " -NoNewline -ForegroundColor Gray
                    Write-Host "未配置" -ForegroundColor Red
                }

                if ($hasTavilyKey) {
                    Write-Host "  • Tavily 密钥: $(Format-APIKeyDisplay $existingKeys['TAVILY_API_KEY'])" -ForegroundColor Gray
                } else {
                    Write-Host "  • Tavily 密钥: " -NoNewline -ForegroundColor Gray
                    Write-Host "未配置" -ForegroundColor Red
                }

                if ($hasBochaKey) {
                    Write-Host "  • Bocha 密钥: $(Format-APIKeyDisplay $existingKeys['BOCHA_WEB_SEARCH_API_KEY'])" -ForegroundColor Gray
                } else {
                    Write-Host "  • Bocha 密钥: " -NoNewline -ForegroundColor Gray
                    Write-Host "未配置" -ForegroundColor Red
                }
                Write-Host ""

                # 如果缺少关键配置,提示用户重新配置
                if (-not ($hasMainKey -and $hasTavilyKey -and $hasBochaKey)) {
                    Write-Host "⚠️  检测到配置不完整,建议重新配置 (输入 n)" -ForegroundColor Yellow
                    Write-Host ""
                }

                # 如果配置完整,询问是否使用
                if ($hasMainKey -and $hasTavilyKey -and $hasBochaKey) {
                    $useExisting = Read-Host "是否使用现有配置? (Y/n)"
                    if ($useExisting -eq '' -or $useExisting -eq 'Y' -or $useExisting -eq 'y') {
                        Write-Success "使用现有配置"
                        return $existingKeys
                    }
                } else {
                    # 配置不完整,询问是补充还是重新配置
                    Write-Host "选择操作:" -ForegroundColor Cyan
                    Write-Host "  [1] 只补充缺失的密钥 (推荐)" -ForegroundColor White
                    Write-Host "  [2] 重新配置所有密钥" -ForegroundColor White
                    Write-Host ""
                    $choice = Read-Host "请选择 [1-2]"

                    if ($choice -eq '1' -or $choice -eq '') {
                        Write-Info "将补充缺失的密钥配置"
                        Write-Host ""

                        # 使用已有配置作为基础
                        $apiKeys = $existingKeys.Clone()

                        # 只补充缺失的配置
                        if (-not $hasMainKey) {
                            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
                            Write-Host "  补充主 API 密钥" -ForegroundColor Cyan
                            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
                            Write-Host ""
                            $mainKey = Read-APIKey -Prompt "主 API 密钥" -Name "主 API 密钥" -Type "main" -Required $true

                            # 设置所有引擎密钥
                            $apiKeys['INSIGHT_ENGINE_API_KEY'] = $mainKey
                            $apiKeys['MEDIA_ENGINE_API_KEY'] = $mainKey
                            $apiKeys['MINDSPIDER_API_KEY'] = $mainKey
                            $apiKeys['QUERY_ENGINE_API_KEY'] = $mainKey
                            $apiKeys['REPORT_ENGINE_API_KEY'] = $mainKey
                            $apiKeys['FORUM_HOST_API_KEY'] = $mainKey
                            $apiKeys['KEYWORD_OPTIMIZER_API_KEY'] = $mainKey

                            $baseUrl = "https://vibecodingapi.ai/v1"
                            $apiKeys['INSIGHT_ENGINE_BASE_URL'] = $baseUrl
                            $apiKeys['MEDIA_ENGINE_BASE_URL'] = $baseUrl
                            $apiKeys['MINDSPIDER_BASE_URL'] = $baseUrl
                            $apiKeys['QUERY_ENGINE_BASE_URL'] = $baseUrl
                            $apiKeys['REPORT_ENGINE_BASE_URL'] = $baseUrl
                            $apiKeys['FORUM_HOST_BASE_URL'] = $baseUrl
                            $apiKeys['KEYWORD_OPTIMIZER_BASE_URL'] = $baseUrl
                        }

                        if (-not $hasTavilyKey) {
                            Write-Host ""
                            $tavilyKey = Read-APIKey -Prompt "Tavily API 密钥" -Name "Tavily API 密钥" -Type "tavily" -Required $true
                            $apiKeys['TAVILY_API_KEY'] = $tavilyKey
                        }

                        if (-not $hasBochaKey) {
                            Write-Host ""
                            $bochaKey = Read-APIKey -Prompt "Bocha API 密钥" -Name "Bocha API 密钥" -Type "bocha" -Required $true
                            $apiKeys['BOCHA_WEB_SEARCH_API_KEY'] = $bochaKey
                            $apiKeys['BOCHA_BASE_URL'] = "https://api.bochaai.com/v1/ai-search"
                        }

                        Write-Host ""
                        Write-Success "密钥补充完成"
                        return $apiKeys
                    }
                }
            }
        } catch {
            Write-Warning "读取现有配置失败,将重新配置"
        }
    }

    # 完整重新配置所有密钥
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  API 配置" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""

    $mainKey = Read-APIKey -Prompt "主 API 密钥" -Name "主 API 密钥" -Type "main" -Required $true
    $baseUrl = "https://vibecodingapi.ai/v1"
    Write-Host ""
    Write-Info "API Base URL: $baseUrl"

    # 设置所有引擎密钥
    $apiKeys['INSIGHT_ENGINE_API_KEY'] = $mainKey
    $apiKeys['MEDIA_ENGINE_API_KEY'] = $mainKey
    $apiKeys['MINDSPIDER_API_KEY'] = $mainKey
    $apiKeys['QUERY_ENGINE_API_KEY'] = $mainKey
    $apiKeys['REPORT_ENGINE_API_KEY'] = $mainKey
    $apiKeys['FORUM_HOST_API_KEY'] = $mainKey
    $apiKeys['KEYWORD_OPTIMIZER_API_KEY'] = $mainKey

    $apiKeys['INSIGHT_ENGINE_BASE_URL'] = $baseUrl
    $apiKeys['MEDIA_ENGINE_BASE_URL'] = $baseUrl
    $apiKeys['MINDSPIDER_BASE_URL'] = $baseUrl
    $apiKeys['QUERY_ENGINE_BASE_URL'] = $baseUrl
    $apiKeys['REPORT_ENGINE_BASE_URL'] = $baseUrl
    $apiKeys['FORUM_HOST_BASE_URL'] = $baseUrl
    $apiKeys['KEYWORD_OPTIMIZER_BASE_URL'] = $baseUrl

    # Tavily API 密钥
    Write-Host ""
    $tavilyKey = Read-APIKey -Prompt "Tavily API 密钥" -Name "Tavily API 密钥" -Type "tavily" -Required $true
    $apiKeys['TAVILY_API_KEY'] = $tavilyKey

    # Bocha API 密钥
    Write-Host ""
    $bochaKey = Read-APIKey -Prompt "Bocha API 密钥" -Name "Bocha API 密钥" -Type "bocha" -Required $true
    $apiKeys['BOCHA_WEB_SEARCH_API_KEY'] = $bochaKey
    $apiKeys['BOCHA_BASE_URL'] = "https://api.bochaai.com/v1/ai-search"

    # 显示配置摘要
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host "  配置摘要" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host ""

    # 获取主密钥显示(从任一引擎配置中获取)
    $displayMainKey = if ($apiKeys.ContainsKey('INSIGHT_ENGINE_API_KEY')) {
        $apiKeys['INSIGHT_ENGINE_API_KEY']
    } elseif ($apiKeys.ContainsKey('QUERY_ENGINE_API_KEY')) {
        $apiKeys['QUERY_ENGINE_API_KEY']
    } else {
        $mainKey
    }

    Write-Host "  • 主 API 密钥: $(Format-APIKeyDisplay $displayMainKey)" -ForegroundColor White
    Write-Host "  • Base URL: https://vibecodingapi.ai/v1" -ForegroundColor White
    Write-Host "  • Tavily 密钥: $(Format-APIKeyDisplay $apiKeys['TAVILY_API_KEY'])" -ForegroundColor White
    Write-Host "  • Bocha 密钥: $(Format-APIKeyDisplay $apiKeys['BOCHA_WEB_SEARCH_API_KEY'])" -ForegroundColor White
    Write-Host ""

    Write-Success "API 配置收集完成"

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

    # 获取主密钥 - 优先从引擎配置中获取(兼容补充密钥的情况)
    $mainKey = if ($APIKeys.ContainsKey('INSIGHT_ENGINE_API_KEY') -and $APIKeys['INSIGHT_ENGINE_API_KEY']) {
        $APIKeys['INSIGHT_ENGINE_API_KEY']
    } elseif ($APIKeys.ContainsKey('QUERY_ENGINE_API_KEY') -and $APIKeys['QUERY_ENGINE_API_KEY']) {
        $APIKeys['QUERY_ENGINE_API_KEY']
    } elseif ($APIKeys.ContainsKey('AGENT_API_KEY')) {
        $APIKeys['AGENT_API_KEY']
    } else {
        # 从任意已配置的引擎中获取
        $engineKeys = @('MEDIA_ENGINE_API_KEY', 'MINDSPIDER_API_KEY', 'REPORT_ENGINE_API_KEY', 'FORUM_HOST_API_KEY', 'KEYWORD_OPTIMIZER_API_KEY')
        foreach ($key in $engineKeys) {
            if ($APIKeys.ContainsKey($key) -and $APIKeys[$key]) {
                $APIKeys[$key]
                break
            }
        }
    }

    # 获取 Base URL
    $baseUrl = if ($APIKeys.ContainsKey('INSIGHT_ENGINE_BASE_URL') -and $APIKeys['INSIGHT_ENGINE_BASE_URL']) {
        $APIKeys['INSIGHT_ENGINE_BASE_URL']
    } elseif ($APIKeys.ContainsKey('AGENT_API_BASE_URL')) {
        $APIKeys['AGENT_API_BASE_URL']
    } else {
        "https://vibecodingapi.ai/v1"
    }

    # 获取或生成数据库密码 - 如果已有配置则保留原密码
    $dbPassword = if ($APIKeys.ContainsKey('DB_PASSWORD') -and $APIKeys['DB_PASSWORD']) {
        $APIKeys['DB_PASSWORD']
    } else {
        "bettafish_secure_$(Get-Random -Minimum 1000000000 -Maximum 9999999999)"
    }

    $envContent = @"
# ====================== BETTAFISH 相关 ======================
# BETTAFISH 主机地址，例如：0.0.0.0 或 127.0.0.1
HOST=0.0.0.0
# BETTAFISH 主机端口，默认为5000
PORT=5000

# ====================== 数据库配置 ======================
# 数据库主机，例如localhost 或 127.0.0.1
DB_HOST=db
# 数据库端口号，PostgreSQL默认为5432
DB_PORT=5432
# 数据库用户名
DB_USER=bettafish
# 数据库密码
DB_PASSWORD=$dbPassword
# 数据库名称
DB_NAME=bettafish
# 数据库字符集，推荐utf8mb4，兼容emoji
DB_CHARSET=utf8mb4
# 数据库类型mysql或postgresql
DB_DIALECT=postgresql

# ======================= LLM 相关 =======================
# 您可以更改每个部分LLM使用的API，🚩只要兼容OpenAI请求格式都可以，定义好KEY、BASE_URL与MODEL_NAME即可正常使用。

# Insight Agent（洞察引擎）
INSIGHT_ENGINE_API_KEY=$mainKey
INSIGHT_ENGINE_BASE_URL=$baseUrl
INSIGHT_ENGINE_MODEL_NAME=gpt-4o

# Media Agent（媒体引擎）
MEDIA_ENGINE_API_KEY=$mainKey
MEDIA_ENGINE_BASE_URL=$baseUrl
MEDIA_ENGINE_MODEL_NAME=gpt-4o

# Query Agent（查询引擎）
QUERY_ENGINE_API_KEY=$mainKey
QUERY_ENGINE_BASE_URL=$baseUrl
QUERY_ENGINE_MODEL_NAME=gpt-4o

# Report Agent（报告引擎）
REPORT_ENGINE_API_KEY=$mainKey
REPORT_ENGINE_BASE_URL=$baseUrl
REPORT_ENGINE_MODEL_NAME=gemini-2.5-pro

# MindSpider Agent（爬虫引擎）
MINDSPIDER_API_KEY=$mainKey
MINDSPIDER_BASE_URL=$baseUrl
MINDSPIDER_MODEL_NAME=deepseek-chat

# 论坛主持人
FORUM_HOST_API_KEY=$mainKey
FORUM_HOST_BASE_URL=$baseUrl
FORUM_HOST_MODEL_NAME=gpt-4o

# SQL Keyword Optimizer（关键词优化器）
KEYWORD_OPTIMIZER_API_KEY=$mainKey
KEYWORD_OPTIMIZER_BASE_URL=$baseUrl
KEYWORD_OPTIMIZER_MODEL_NAME=gpt-3.5-turbo

# ================== 网络工具配置 ====================
# Tavily API密钥，用于Tavily网络搜索
TAVILY_API_KEY=$($APIKeys['TAVILY_API_KEY'])

# Bocha AI Search，用于Bocha多模态搜索
BOCHA_BASE_URL=https://api.bochaai.com/v1/ai-search
BOCHA_WEB_SEARCH_API_KEY=$($APIKeys['BOCHA_WEB_SEARCH_API_KEY'])
"@

    try {
        $utf8NoBOM = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($envFile, $envContent, $utf8NoBOM)
        Write-Success "环境文件生成成功"
        Write-Host ""
        Write-Info "配置文件位置: $envFile"
        return $true
    } catch {
        Write-Error "环境文件生成失败: $_"
        return $false
    }
}

# ================================================================
# 镜像源测速和选择
# ================================================================

function Test-MirrorSpeed {
    param([string]$Url)

    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $response = Invoke-WebRequest -Uri $Url -Method Head -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        $stopwatch.Stop()
        return $stopwatch.ElapsedMilliseconds
    } catch {
        return 999999  # 超时或失败
    }
}

function Select-MirrorSource {
    Write-Info "测试镜像源网络连接速度..."
    Write-Host ""

    $mirrors = @(
        @{
            Name = "官方源 (ghcr.io)"
            Url = "https://ghcr.io"
            TestUrl = "https://ghcr.io/v2/"
            BettaFishImage = "ghcr.io/666ghj/bettafish:latest"
        },
        @{
            Name = "南京大学镜像 (ghcr.nju.edu.cn)"
            Url = "https://ghcr.nju.edu.cn"
            TestUrl = "https://ghcr.nju.edu.cn/v2/"
            BettaFishImage = "ghcr.nju.edu.cn/666ghj/bettafish:latest"
        }
    )

    Write-Host "测试结果:" -ForegroundColor Cyan

    $results = @()
    $index = 1

    foreach ($mirror in $mirrors) {
        Write-Host -NoNewline "  [$index] $($mirror.Name) ... "

        $speed = Test-MirrorSpeed -Url $mirror.TestUrl

        if ($speed -lt 999999) {
            Write-Host "$speed ms" -ForegroundColor Green
            $results += @{
                Index = $index
                Name = $mirror.Name
                Speed = $speed
                Image = $mirror.BettaFishImage
            }
        } else {
            Write-Host "超时" -ForegroundColor Red
        }

        $index++
    }

    Write-Host ""

    if ($results.Count -eq 0) {
        Write-Warning "所有镜像源都无法访问"
        return $mirrors[0].BettaFishImage  # 默认返回官方源
    }

    # 找出最快的镜像源
    $fastest = $results | Sort-Object Speed | Select-Object -First 1

    Write-Success "推荐镜像源: $($fastest.Name) ($($fastest.Speed)ms)"
    Write-Host ""

    # 让用户选择
    Write-Host "请选择镜像源 [1-$($mirrors.Count)] (回车默认使用推荐): " -NoNewline
    $choice = Read-Host

    if ([string]::IsNullOrWhiteSpace($choice)) {
        Write-Info "使用推荐镜像源: $($fastest.Name)"
        return $fastest.Image
    }

    $choiceIndex = [int]$choice
    if ($choiceIndex -ge 1 -and $choiceIndex -le $mirrors.Count) {
        $selected = $mirrors[$choiceIndex - 1]
        Write-Info "使用镜像源: $($selected.Name)"
        return $selected.BettaFishImage
    } else {
        Write-Warning "无效选择，使用推荐镜像源"
        return $fastest.Image
    }
}

# ================================================================
# Docker 镜像管理
# ================================================================

function Manage-DockerImages {
    param([string]$BettaFishImage)

    Write-Info "检查 Docker 镜像..."
    Write-Host ""

    # 检查 PostgreSQL 镜像
    $postgresExists = docker images postgres:15 --format "{{.Repository}}" 2>$null | Select-Object -First 1

    if ($postgresExists -eq "postgres") {
        Write-Success "PostgreSQL 镜像已存在"
    } else {
        Write-Info "正在拉取 PostgreSQL 镜像..."
        Write-Host "  (镜像大小约 250MB)" -ForegroundColor Gray
        Write-Host "  (提示: 首次拉取可能需要几分钟,请耐心等待...)" -ForegroundColor Gray
        Write-Host ""

        # 优先使用 DaoCloud 镜像加速源 (绕过用户 Docker 配置的镜像源问题)
        Write-Info "尝试使用 DaoCloud 镜像加速源..."
        docker pull docker.m.daocloud.io/postgres:15

        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Info "重新标记为 postgres:15..."
            docker tag docker.m.daocloud.io/postgres:15 postgres:15

            # 删除临时镜像,只保留标准名称
            docker rmi docker.m.daocloud.io/postgres:15 2>&1 | Out-Null

            Write-Success "PostgreSQL 镜像拉取成功 (DaoCloud 加速)"
        } else {
            # 尝试南京大学镜像源
            Write-Host ""
            Write-Info "尝试使用南京大学镜像加速源..."
            docker pull docker.nju.edu.cn/postgres:15

            if ($LASTEXITCODE -eq 0) {
                Write-Host ""
                Write-Info "重新标记为 postgres:15..."
                docker tag docker.nju.edu.cn/postgres:15 postgres:15

                # 删除临时镜像
                docker rmi docker.nju.edu.cn/postgres:15 2>&1 | Out-Null

                Write-Success "PostgreSQL 镜像拉取成功 (南京大学镜像)"
            } else {
                # 最后尝试官方源
                Write-Host ""
                Write-Info "尝试使用官方源..."
                docker pull postgres:15

                if ($LASTEXITCODE -eq 0) {
                    Write-Host ""
                    Write-Success "PostgreSQL 镜像拉取成功"
                } else {
                    Write-Error "PostgreSQL 镜像拉取失败 - 所有镜像源均不可用"
                    Write-Host ""
                    Write-Host "可能的原因:" -ForegroundColor Yellow
                    Write-Host "  1. 网络连接问题" -ForegroundColor White
                    Write-Host "  2. Docker Desktop 配置了无效的镜像源" -ForegroundColor White
                    Write-Host "  3. 所有镜像加速源都无法访问" -ForegroundColor White
                    Write-Host ""
                    Write-Host "建议操作:" -ForegroundColor Yellow
                    Write-Host "  1. 运行 fix-docker-mirrors.bat 清理 Docker 镜像源配置" -ForegroundColor White
                    Write-Host "  2. 打开 Docker Desktop → Settings → Docker Engine" -ForegroundColor White
                    Write-Host "  3. 删除或注释掉 'registry-mirrors' 配置" -ForegroundColor White
                    Write-Host "  4. 点击 'Apply & Restart' 重启 Docker" -ForegroundColor White
                    Write-Host "  5. 重新运行此脚本" -ForegroundColor White
                    Write-Host ""
                    return $false
                }
            }
        }
    }

    Write-Host ""

    # 检查 BettaFish 镜像
    $bettafishExists = docker images ghcr.io/666ghj/bettafish:latest --format "{{.Repository}}" 2>$null | Select-Object -First 1

    if ($bettafishExists -eq "ghcr.io/666ghj/bettafish") {
        Write-Success "BettaFish 镜像已存在"
    } else {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "  拉取 BettaFish 应用镜像" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""

        # 显示使用的镜像源
        if ($BettaFishImage -eq "ghcr.io/666ghj/bettafish:latest") {
            Write-Info "正在从官方源拉取 BettaFish..."
        } else {
            Write-Info "正在从南京大学镜像源拉取 BettaFish..."
        }
        Write-Host ""

        # 显示实时下载进度（不隐藏输出）
        docker pull $BettaFishImage

        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Success "BettaFish 镜像拉取成功"

            # 如果使用镜像源，重新标记为标准名称
            if ($BettaFishImage -ne "ghcr.io/666ghj/bettafish:latest") {
                docker tag $BettaFishImage ghcr.io/666ghj/bettafish:latest
                Write-Info "镜像已重新标记为 ghcr.io/666ghj/bettafish:latest"
            }
        } else {
            # 如果用户选择的源失败，尝试备用源
            if ($BettaFishImage -eq "ghcr.io/666ghj/bettafish:latest") {
                # 用户选择了官方源但失败，尝试镜像源
                Write-Host ""
                Write-Info "官方源拉取失败，尝试使用南京大学镜像源..."
                Write-Host ""
                docker pull ghcr.nju.edu.cn/666ghj/bettafish:latest

                if ($LASTEXITCODE -eq 0) {
                    Write-Host ""
                    Write-Success "BettaFish 镜像拉取成功 (南京大学镜像)"
                    docker tag ghcr.nju.edu.cn/666ghj/bettafish:latest ghcr.io/666ghj/bettafish:latest
                } else {
                    Write-Error "BettaFish 镜像拉取失败 - 所有镜像源均不可用"
                    return $false
                }
            } else {
                # 用户选择了镜像源但失败，尝试官方源
                Write-Host ""
                Write-Info "镜像源拉取失败，尝试使用官方源..."
                Write-Host ""
                docker pull ghcr.io/666ghj/bettafish:latest

                if ($LASTEXITCODE -eq 0) {
                    Write-Success "BettaFish 镜像拉取成功 (官方源)"
                } else {
                    Write-Error "BettaFish 镜像拉取失败 - 所有镜像源均不可用"
                    return $false
                }
            }
        }
    }

    Write-Host ""
    Write-Success "所有镜像准备完成！"
    Write-Host "  ✓ BettaFish 应用镜像" -ForegroundColor Green
    Write-Host "  ✓ PostgreSQL 数据库镜像" -ForegroundColor Green

    return $true
}

# ================================================================
# 主程序入口
# ================================================================

function Main {
    # ASCII Art 标题
    Write-Host ""
    Write-Host "  _      ___ ___  _   _  ____ ____       _    ___" -ForegroundColor Blue
    Write-Host " | |    |_ _/ _ \| \ | |/ ___/ ___|     / \  |_ _|" -ForegroundColor Blue
    Write-Host " | |     | | | | |  \| | |  | |        / _ \  | |" -ForegroundColor Blue
    Write-Host " | |___  | | |_| | |\  | |__| |___  _ / ___ \ | |" -ForegroundColor Blue
    Write-Host " |_____||___\___/|_| \_|\____\____|(_)_/   \_\___|" -ForegroundColor Blue
    Write-Host ""
    Write-Host "       🐟 BettaFish Docker 一键部署" -ForegroundColor Cyan
    Write-Host "        Powered by LIONCC.AI - 2025" -ForegroundColor Gray
    Write-Host ""

    # 步骤 1/7: 环境检测
    Write-StepHeader -Step 1 -Total 7 -Title "环境检测与依赖检查"

    Write-Info "PowerShell 版本: $($PSVersionTable.PSVersion)"

    # 检查 Docker
    Write-Info "检测 Docker Desktop..."

    # 检查 Docker 是否已安装
    $ErrorActionPreference = 'SilentlyContinue'
    $dockerVersion = docker --version 2>$null
    $dockerInstalled = $LASTEXITCODE -eq 0
    $ErrorActionPreference = 'Continue'

    if (-not $dockerInstalled) {
        Write-Error "Docker Desktop 未安装"
        Write-Host ""
        Write-Host "请访问以下网址下载并安装 Docker Desktop:" -ForegroundColor Yellow
        Write-Host "  https://www.docker.com/products/docker-desktop" -ForegroundColor Cyan
        Write-Host ""
        Read-Host "按回车键退出"
        exit 1
    }

    Write-Success "Docker 已安装: $dockerVersion"

    # 检查 Docker 是否正在运行
    Write-Host ""
    Write-Info "检查 Docker 运行状态..."
    $ErrorActionPreference = 'SilentlyContinue'
    $dockerInfo = docker info 2>$null
    $dockerRunning = $LASTEXITCODE -eq 0
    $ErrorActionPreference = 'Continue'

    if (-not $dockerRunning) {
        Write-Warning "Docker Desktop 未运行"
        Write-Host ""
        Write-Info "正在尝试自动启动 Docker Desktop..."

        # 尝试查找 Docker Desktop 可执行文件
        $dockerPaths = @(
            "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe",
            "${env:ProgramFiles(x86)}\Docker\Docker\Docker Desktop.exe",
            "$env:LOCALAPPDATA\Docker\Docker Desktop.exe"
        )

        $dockerExe = $null
        foreach ($path in $dockerPaths) {
            if (Test-Path $path) {
                $dockerExe = $path
                break
            }
        }

        if ($dockerExe) {
            Write-Info "找到 Docker Desktop: $dockerExe"
            Write-Host ""

            try {
                # 启动 Docker Desktop
                Start-Process -FilePath $dockerExe -WindowStyle Hidden

                Write-Info "Docker Desktop 启动中,请稍候..."
                Write-Host ""

                # 等待 Docker 启动(最多等待 120 秒)
                $maxWaitSeconds = 120
                $waitInterval = 5
                $elapsed = 0

                while ($elapsed -lt $maxWaitSeconds) {
                    Start-Sleep -Seconds $waitInterval
                    $elapsed += $waitInterval

                    # 检查 Docker 是否已启动
                    $ErrorActionPreference = 'SilentlyContinue'
                    docker info 2>$null | Out-Null
                    $dockerReady = $LASTEXITCODE -eq 0
                    $ErrorActionPreference = 'Continue'

                    if ($dockerReady) {
                        Write-Host ""
                        Write-Success "Docker Desktop 启动成功! (耗时 $elapsed 秒)"
                        break
                    }

                    # 显示进度
                    $progress = [math]::Min(100, ($elapsed / $maxWaitSeconds) * 100)
                    Write-Host "`r  等待中... $elapsed/$maxWaitSeconds 秒 [$([math]::Floor($progress))%]" -NoNewline -ForegroundColor Gray
                }

                Write-Host ""  # 换行

                if (-not $dockerReady) {
                    Write-Warning "Docker Desktop 启动超时"
                    Write-Host ""
                    Write-Host "请手动检查:" -ForegroundColor Yellow
                    Write-Host "  1. 查看任务栏右下角是否有 Docker 图标" -ForegroundColor White
                    Write-Host "  2. 图标是否还在转圈(表示仍在启动中)" -ForegroundColor White
                    Write-Host "  3. 如果仍在启动,请等待完成后重新运行脚本" -ForegroundColor White
                    Write-Host ""
                    Read-Host "按回车键退出"
                    exit 1
                }

            } catch {
                Write-Error "启动 Docker Desktop 失败: $_"
                Write-Host ""
                Write-Host "请手动启动 Docker Desktop 后重新运行脚本" -ForegroundColor Yellow
                Write-Host ""
                Read-Host "按回车键退出"
                exit 1
            }
        } else {
            Write-Error "无法找到 Docker Desktop 可执行文件"
            Write-Host ""
            Write-Host "请手动启动 Docker Desktop:" -ForegroundColor Yellow
            Write-Host "  1. 在开始菜单搜索 'Docker Desktop'" -ForegroundColor White
            Write-Host "  2. 打开应用程序并等待启动完成" -ForegroundColor White
            Write-Host "  3. 重新运行此脚本" -ForegroundColor White
            Write-Host ""
            Read-Host "按回车键退出"
            exit 1
        }
    } else {
        Write-Success "Docker 运行正常"
    }

    # 检查 Docker 镜像源配置
    Write-Host ""
    Write-Info "检查 Docker 镜像源配置..."
    $dockerConfigPath = "$env:USERPROFILE\.docker\daemon.json"

    if (Test-Path $dockerConfigPath) {
        $configContent = Get-Content $dockerConfigPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($configContent -match 'docker\.1panel\.live') {
            Write-Warning "检测到无效的 Docker 镜像源配置"
            Write-Host ""
            Write-Host "您的 Docker Desktop 配置了无效的镜像源 'docker.1panel.live'" -ForegroundColor Yellow
            Write-Host "这会导致镜像拉取失败 (403 Forbidden)" -ForegroundColor Yellow
            Write-Host ""

            $autoFix = Read-Host "是否自动清理无效镜像源配置? (Y/n)"
            if ($autoFix -eq '' -or $autoFix -eq 'Y' -or $autoFix -eq 'y') {
                try {
                    # 备份原配置
                    $backupPath = "$dockerConfigPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                    Copy-Item $dockerConfigPath $backupPath
                    Write-Info "已备份原配置到: $backupPath"

                    # 解析并清理配置
                    $config = $configContent | ConvertFrom-Json
                    if ($config.PSObject.Properties.Name -contains 'registry-mirrors') {
                        $config.PSObject.Properties.Remove('registry-mirrors')
                    }

                    # 保存新配置
                    $newConfig = $config | ConvertTo-Json -Depth 10
                    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
                    [System.IO.File]::WriteAllText($dockerConfigPath, $newConfig, $utf8NoBom)

                    Write-Success "镜像源配置已清理"
                    Write-Host ""
                    Write-Info "正在重启 Docker Desktop..."

                    # 重启 Docker Desktop
                    Stop-Process -Name "Docker Desktop" -Force -ErrorAction SilentlyContinue
                    Start-Sleep -Seconds 3

                    # 启动 Docker Desktop
                    $dockerExe = "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
                    if (Test-Path $dockerExe) {
                        Start-Process -FilePath $dockerExe -WindowStyle Hidden

                        Write-Info "等待 Docker 重启..."
                        $maxWait = 60
                        $waited = 0
                        while ($waited -lt $maxWait) {
                            Start-Sleep -Seconds 5
                            $waited += 5

                            $ErrorActionPreference = 'SilentlyContinue'
                            docker info 2>$null | Out-Null
                            $dockerReady = $LASTEXITCODE -eq 0
                            $ErrorActionPreference = 'Continue'

                            if ($dockerReady) {
                                Write-Success "Docker 重启完成"
                                break
                            }

                            Write-Host "`r  等待中... $waited/$maxWait 秒" -NoNewline -ForegroundColor Gray
                        }
                        Write-Host ""
                        Write-Host ""
                    }

                } catch {
                    Write-Error "自动清理失败: $_"
                    Write-Host ""
                    Write-Host "请手动修复:" -ForegroundColor Yellow
                    Write-Host "  1. 打开 Docker Desktop → Settings → Docker Engine" -ForegroundColor White
                    Write-Host "  2. 删除 'registry-mirrors' 配置" -ForegroundColor White
                    Write-Host "  3. 点击 'Apply & Restart'" -ForegroundColor White
                    Write-Host ""
                    Read-Host "按回车键退出"
                    exit 1
                }
            } else {
                Write-Host ""
                Write-Host "请手动清理后重新运行部署脚本" -ForegroundColor Yellow
                Write-Host ""
                Read-Host "按回车键退出"
                exit 1
            }
        }
    }

    # 步骤 2/7: 项目源码检测
    Write-StepHeader -Step 2 -Total 7 -Title "检测 BettaFish 项目源码"

    if (-not (Test-Path $PROJECT_DIR)) {
        Write-Error "找不到 BettaFish-main 目录"
        Write-Info "请先运行 download-project.bat 下载项目源码"
        Read-Host "按回车键退出"
        exit 1
    }

    Write-Success "项目源码已就绪: $PROJECT_DIR"

    # 步骤 3/7: API 配置
    Write-StepHeader -Step 3 -Total 7 -Title "API 密钥配置"

    $apiKeys = Get-APIConfiguration

    # 步骤 4/7: 环境文件生成
    Write-StepHeader -Step 4 -Total 7 -Title "生成环境配置文件"

    if (-not (Generate-EnvFile -APIKeys $apiKeys)) {
        Write-Error "环境文件生成失败"
        Read-Host "按回车键退出"
        exit 1
    }

    # 步骤 5/7: 镜像源选择和拉取
    Write-StepHeader -Step 5 -Total 7 -Title "镜像源选择与 Docker 镜像拉取"

    $bettafishImage = Select-MirrorSource

    Write-Host ""

    if (-not (Manage-DockerImages -BettaFishImage $bettafishImage)) {
        Write-Error "Docker 镜像拉取失败"
        Read-Host "按回车键退出"
        exit 1
    }

    # 步骤 6/7: 启动服务
    Write-StepHeader -Step 6 -Total 7 -Title "启动 Docker 容器"

    Push-Location $PROJECT_DIR
    try {
        # 检查并清理可能存在的旧容器
        $existingContainers = docker ps -a --filter "name=bettafish" --format "{{.Names}}" 2>$null
        if ($existingContainers) {
            Write-Info "检测到已存在的容器,正在清理..."

            # 先尝试 docker-compose down
            $ErrorActionPreference = 'SilentlyContinue'
            docker-compose down *>&1 | Out-Null
            $ErrorActionPreference = 'Continue'

            # 强制删除所有相关容器(包括孤立容器)
            $containers = docker ps -a --filter "name=bettafish" --format "{{.ID}}" 2>$null
            if ($containers) {
                foreach ($container in $containers) {
                    docker rm -f $container 2>&1 | Out-Null
                }
            }

            Write-Success "旧容器已清理"
        }

        Write-Info "运行 docker-compose up -d..."
        docker-compose up -d

        if ($LASTEXITCODE -eq 0) {
            Write-Success "容器启动成功"

            # 等待几秒后检查容器健康状态
            Write-Host ""
            Write-Info "检查容器运行状态..."
            Start-Sleep -Seconds 3

            $unhealthyContainers = docker ps -a --filter "name=bettafish" --filter "status=exited" --format "{{.Names}}" 2>$null
            if ($unhealthyContainers) {
                Write-Warning "检测到容器启动后立即退出"
                Write-Host ""
                Write-Info "正在尝试重新启动容器..."

                # 尝试重启容器(最多重试 3 次)
                $maxRetries = 3
                $retryCount = 0
                $success = $false

                while ($retryCount -lt $maxRetries -and -not $success) {
                    $retryCount++
                    Write-Host ""
                    Write-Info "重试 $retryCount/$maxRetries..."

                    # 停止并删除所有容器
                    docker-compose down *>&1 | Out-Null
                    Start-Sleep -Seconds 2

                    # 重新启动
                    docker-compose up -d *>&1 | Out-Null

                    if ($LASTEXITCODE -eq 0) {
                        Start-Sleep -Seconds 5

                        # 检查容器状态
                        $runningContainers = docker ps --filter "name=bettafish" --format "{{.Names}}" 2>$null
                        if ($runningContainers -and ($runningContainers -match "bettafish")) {
                            Write-Success "容器重启成功"
                            $success = $true
                        }
                    }
                }

                if (-not $success) {
                    Write-Error "容器重启失败"
                    Write-Host ""
                    Write-Host "请检查日志:" -ForegroundColor Yellow
                    Write-Host "  docker-compose logs" -ForegroundColor White
                    Write-Host ""
                    Pop-Location
                    Read-Host "按回车键退出"
                    exit 1
                }
            } else {
                # 验证容器是否正在运行
                $runningContainers = docker ps --filter "name=bettafish" --format "{{.Names}}" 2>$null
                if ($runningContainers) {
                    Write-Success "所有容器运行正常"
                    Write-Host ""
                    Write-Host "运行中的容器:" -ForegroundColor Gray
                    foreach ($container in $runningContainers) {
                        Write-Host "  ✓ $container" -ForegroundColor Green
                    }
                }
            }
        } else {
            Write-Error "容器启动失败"
            Write-Host ""
            Write-Host "请检查错误信息并尝试以下操作:" -ForegroundColor Yellow
            Write-Host "  1. 查看详细日志: docker-compose logs" -ForegroundColor White
            Write-Host "  2. 检查端口占用: netstat -ano | findstr :5000" -ForegroundColor White
            Write-Host "  3. 重新运行部署脚本" -ForegroundColor White
            Write-Host ""
            Pop-Location
            Read-Host "按回车键退出"
            exit 1
        }
    } finally {
        Pop-Location
    }

    # 步骤 7/7: 部署完成
    Write-StepHeader -Step 7 -Total 7 -Title "部署完成"

    Write-Success "BettaFish 部署成功！"
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host "  访问地址" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host ""
    Write-Host "  本地访问: http://localhost:5000" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  数据库配置信息" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "在 BettaFish 界面中配置数据库连接:" -ForegroundColor White
    Write-Host "  • 数据库类型: postgresql" -ForegroundColor Gray
    Write-Host "  • 主机地址: db" -ForegroundColor Gray
    Write-Host "  • 端口: 5432" -ForegroundColor Gray
    Write-Host "  • 用户名: bettafish" -ForegroundColor Gray
    Write-Host "  • 数据库名: bettafish" -ForegroundColor Gray

    # 读取并显示数据库密码
    $envFile = Join-Path $PROJECT_DIR ".env"
    if (Test-Path $envFile) {
        $dbPassword = Get-Content $envFile | Select-String "^DB_PASSWORD=" | ForEach-Object { $_ -replace "^DB_PASSWORD=", "" }
        if ($dbPassword) {
            Write-Host "  • 密码: " -NoNewline -ForegroundColor Gray
            Write-Host "$dbPassword" -ForegroundColor Yellow
        }
    }

    Write-Host ""

    Read-Host "按回车键打开默认浏览器"

    # 自动打开浏览器
    try {
        Start-Process "http://localhost:5000"
        Write-Success "已在默认浏览器中打开 BettaFish"
    } catch {
        Write-Warning "自动打开浏览器失败,请手动访问: http://localhost:5000"
    }
}

# 执行主程序
Main
