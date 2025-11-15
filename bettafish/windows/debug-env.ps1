# 调试脚本 - 检查 .env 文件读取问题
$ErrorActionPreference = 'Stop'

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_DIR = Join-Path $SCRIPT_DIR "BettaFish-main"
$envFile = Join-Path $PROJECT_DIR ".env"

Write-Host "========================================"  -ForegroundColor Cyan
Write-Host "  .env 文件诊断工具" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "脚本目录: $SCRIPT_DIR" -ForegroundColor Yellow
Write-Host "项目目录: $PROJECT_DIR" -ForegroundColor Yellow
Write-Host ".env 路径: $envFile" -ForegroundColor Yellow
Write-Host ""

# 检查项目目录是否存在
if (-not (Test-Path $PROJECT_DIR)) {
    Write-Host "❌ 项目目录不存在: $PROJECT_DIR" -ForegroundColor Red
    Write-Host ""
    Write-Host "请先运行 download-project.bat 下载项目源码" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "按回车键退出"
    exit 1
}

Write-Host "✅ 项目目录存在" -ForegroundColor Green
Write-Host ""

# 检查 .env 文件是否存在
if (-not (Test-Path $envFile)) {
    Write-Host "❌ .env 文件不存在: $envFile" -ForegroundColor Red
    Write-Host ""
    Write-Host "这是第一次运行,还没有生成 .env 文件" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "按回车键退出"
    exit 0
}

Write-Host "✅ .env 文件存在" -ForegroundColor Green
Write-Host ""

# 读取 .env 文件内容
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  .env 文件内容 (完整)" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
$envContent = Get-Content $envFile -Encoding UTF8
$envContent | ForEach-Object { Write-Host $_ -ForegroundColor Gray }
Write-Host ""

# 解析引擎密钥
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  引擎密钥检测" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

$existingKeys = @{}
foreach ($line in $envContent) {
    if ($line -match '^([^#][^=]+)=(.*)$') {
        $key = $Matches[1].Trim()
        $value = $Matches[2].Trim()
        if ($value) {
            $existingKeys[$key] = $value
        }
    }
}

$engineKeys = @(
    'INSIGHT_ENGINE_API_KEY',
    'MEDIA_ENGINE_API_KEY',
    'MINDSPIDER_API_KEY',
    'QUERY_ENGINE_API_KEY',
    'REPORT_ENGINE_API_KEY',
    'FORUM_HOST_API_KEY',
    'KEYWORD_OPTIMIZER_API_KEY'
)

$hasMainKey = $false
$foundKeys = @()
foreach ($key in $engineKeys) {
    if ($existingKeys.ContainsKey($key) -and $existingKeys[$key]) {
        $hasMainKey = $true
        $maskedValue = $existingKeys[$key].Substring(0, [Math]::Min(8, $existingKeys[$key].Length)) + "***"
        $foundKeys += "$key = $maskedValue"
        Write-Host "  ✅ $key" -ForegroundColor Green
        Write-Host "      值: $maskedValue" -ForegroundColor Gray
    } else {
        Write-Host "  ❌ $key" -ForegroundColor Red
        Write-Host "      未配置" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  其他密钥检测" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

$otherKeys = @('TAVILY_API_KEY', 'BOCHA_WEB_SEARCH_API_KEY', 'DB_PASSWORD')
foreach ($key in $otherKeys) {
    if ($existingKeys.ContainsKey($key) -and $existingKeys[$key]) {
        $maskedValue = $existingKeys[$key].Substring(0, [Math]::Min(6, $existingKeys[$key].Length)) + "***"
        Write-Host "  ✅ $key = $maskedValue" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $key 未配置" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  诊断结果" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

if ($hasMainKey) {
    Write-Host "✅ 主 API 密钥已配置" -ForegroundColor Green
    Write-Host ""
    Write-Host "已配置的引擎密钥:" -ForegroundColor Yellow
    foreach ($found in $foundKeys) {
        Write-Host "  • $found" -ForegroundColor Gray
    }
} else {
    Write-Host "❌ 主 API 密钥未配置" -ForegroundColor Red
    Write-Host ""
    Write-Host "所有引擎密钥都为空!" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  诊断完成" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Read-Host "按回车键退出"
