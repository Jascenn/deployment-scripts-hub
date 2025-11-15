# 🪟 Windows 部署流程分析与设计

## 📊 核心差异对比

| 功能 | Linux/macOS | Windows PowerShell | 需要修改 |
|------|------------|-------------------|---------|
| **Shell 语法** | Bash | PowerShell | ✅ 完全重写 |
| **系统检测** | `uname` | `$env:OS` | ✅ 简单 |
| **Docker 检测** | `systemctl` | `Get-Service` | ✅ 需要检测 Docker Desktop |
| **路径处理** | `/path/to/file` | `C:\path\to\file` | ✅ 使用 `Join-Path` |
| **网络测速** | `curl -w` | `Invoke-WebRequest` + Stopwatch | ✅ 重写 |
| **端口检测** | `lsof`/`netstat` | `Get-NetTCPConnection` | ✅ 更简单 |
| **防火墙** | `firewalld`/`ufw` | `New-NetFirewallRule` | ✅ 需要管理员 |
| **彩色输出** | ANSI codes | `Write-Host -ForegroundColor` | ✅ 更简单 |
| **进度条** | ASCII 手绘 | `Write-Progress` | ✅ 原生支持 |

---

## ⚠️ Windows 特有问题

### 1. 执行策略限制
```powershell
# 问题：无法运行脚本
.\docker-deploy.ps1
# 错误: 无法加载文件，因为在此系统上禁止运行脚本

# 解决：使用批处理包装器（推荐）
# docker-deploy.bat
@echo off
powershell -ExecutionPolicy Bypass -File "%~dp0docker-deploy.ps1"
pause
```

### 2. 管理员权限
```powershell
# 检测并自动提权
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "需要管理员权限，正在提权..." -ForegroundColor Yellow
    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}
```

### 3. Docker Desktop 未启动
```powershell
# 检测并自动启动
$dockerProcess = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue
if ($null -eq $dockerProcess) {
    Write-Host "正在启动 Docker Desktop..." -ForegroundColor Yellow
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"

    # 等待启动
    $timeout = 60
    while ($timeout -gt 0) {
        try {
            docker ps | Out-Null
            break
        } catch {
            Start-Sleep -Seconds 5
            $timeout -= 5
        }
    }
}
```

---

## 🎯 优化后的 Windows 执行流程

```
1. 前置检查 ⭐ Windows 特有
   ├── 检测管理员权限 → 自动提权 (UAC)
   ├── 检测 PowerShell 版本 (≥ 5.1)
   └── 设置控制台编码 (UTF-8)

2. 环境检测
   ├── 检测 Docker Desktop 安装
   ├── 检测 Docker Desktop 运行状态 → 自动启动 ⭐
   ├── 检测 WSL2 配置 ⭐
   └── 检测网络连接

3. 项目准备
   ├── 查找 BettaFish-main 目录
   └── 验证 docker-compose.yml

4. API 配置
   ├── 读取现有配置
   ├── 交互式输入 (支持 SecureString) ⭐
   └── 生成 .env 文件

5. 镜像管理
   ├── 测试镜像源速度 (Stopwatch) ⭐
   ├── 选择最快源
   └── 拉取镜像 (Write-Progress) ⭐

6. 服务部署
   ├── 端口检测 (Get-NetTCPConnection) ⭐
   ├── docker-compose up -d
   └── 健康检查

7. 网络配置
   ├── 配置 Windows Firewall ⭐
   └── 显示访问地址

8. 完成
   └── 显示管理命令
```

---

## 📦 文件结构

```
Windows-Version/
├── docker-deploy.bat           # 入口（双击运行）
├── docker-deploy.ps1           # 主脚本 (3000+ 行)
├── docker-cleanup.bat
├── docker-cleanup.ps1
├── diagnose.bat
├── diagnose.ps1
├── README-Windows.md           # Windows 使用文档
└── modules/                    # PowerShell 模块（可选）
    ├── DockerHelper.psm1
    ├── NetworkHelper.psm1
    └── FirewallHelper.psm1
```

---

## 🚀 关键改进

### 1. 自动化提升
- ✅ 自动检测并启动 Docker Desktop
- ✅ 自动提权（管理员）
- ✅ 自动配置防火墙

### 2. 用户体验
- ✅ 原生进度条 `Write-Progress`
- ✅ 彩色输出更简洁
- ✅ 错误提示更友好

### 3. Windows 优化
- ✅ WSL2 性能建议
- ✅ 路径处理更安全
- ✅ 编码问题自动处理

---

**下一步**: 创建 PowerShell 部署脚本
