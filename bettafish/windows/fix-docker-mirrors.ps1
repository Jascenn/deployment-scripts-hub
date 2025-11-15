#Requires -Version 5.1

# ================================================================
# Docker 镜像源修复工具
# 用于清理无效的 Docker 镜像源配置
# ================================================================

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Docker 镜像源修复工具" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检测 Docker Desktop 配置文件位置
$dockerConfigPath = "$env:USERPROFILE\.docker\daemon.json"

if (-not (Test-Path $dockerConfigPath)) {
    Write-Host "未找到 Docker 配置文件,无需修复" -ForegroundColor Green
    Write-Host ""
    Read-Host "按回车键退出"
    exit 0
}

Write-Host "找到 Docker 配置文件: $dockerConfigPath" -ForegroundColor Yellow
Write-Host ""

# 读取当前配置
$configContent = Get-Content $dockerConfigPath -Raw -Encoding UTF8
Write-Host "当前配置内容:" -ForegroundColor Cyan
Write-Host $configContent -ForegroundColor Gray
Write-Host ""

# 检查是否包含无效镜像源
if ($configContent -match 'docker\.1panel\.live') {
    Write-Host "检测到无效镜像源: docker.1panel.live" -ForegroundColor Red
    Write-Host ""

    $confirm = Read-Host "是否清理此镜像源配置? (Y/n)"
    if ($confirm -eq '' -or $confirm -eq 'Y' -or $confirm -eq 'y') {

        # 备份原配置
        $backupPath = "$dockerConfigPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $dockerConfigPath $backupPath
        Write-Host "已备份原配置到: $backupPath" -ForegroundColor Green
        Write-Host ""

        # 解析 JSON
        try {
            $config = $configContent | ConvertFrom-Json

            # 移除 registry-mirrors 配置
            if ($config.PSObject.Properties.Name -contains 'registry-mirrors') {
                $config.PSObject.Properties.Remove('registry-mirrors')
                Write-Host "已移除 registry-mirrors 配置" -ForegroundColor Green
            }

            # 保存新配置
            $newConfig = $config | ConvertTo-Json -Depth 10
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($dockerConfigPath, $newConfig, $utf8NoBom)

            Write-Host ""
            Write-Host "新配置内容:" -ForegroundColor Cyan
            Write-Host $newConfig -ForegroundColor Gray
            Write-Host ""

            Write-Host "========================================" -ForegroundColor Green
            Write-Host "  配置已更新!" -ForegroundColor Green
            Write-Host "========================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "请执行以下步骤:" -ForegroundColor Yellow
            Write-Host "  1. 打开 Docker Desktop" -ForegroundColor White
            Write-Host "  2. 点击右上角设置图标 ⚙️" -ForegroundColor White
            Write-Host "  3. 在任意设置页面点击 'Apply & Restart'" -ForegroundColor White
            Write-Host "  4. 等待 Docker 重启完成" -ForegroundColor White
            Write-Host "  5. 重新运行部署脚本: .\docker-deploy-v4.bat" -ForegroundColor White
            Write-Host ""

        } catch {
            Write-Host "配置文件格式错误,无法自动修复" -ForegroundColor Red
            Write-Host ""
            Write-Host "请手动编辑 Docker Desktop 配置:" -ForegroundColor Yellow
            Write-Host "  1. 打开 Docker Desktop" -ForegroundColor White
            Write-Host "  2. Settings → Docker Engine" -ForegroundColor White
            Write-Host "  3. 删除包含 'docker.1panel.live' 的配置" -ForegroundColor White
            Write-Host "  4. 点击 'Apply & Restart'" -ForegroundColor White
            Write-Host ""
        }
    }
} else {
    Write-Host "未检测到问题,配置正常" -ForegroundColor Green
    Write-Host ""
}

Read-Host "按回车键退出"
