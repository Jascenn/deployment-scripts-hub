# 🚨 关键问题修复指南

**创建日期**: 2025-11-15
**状态**: 诊断中
**影响**: 阻塞部署

---

## 🔴 问题 1: API 密钥不持久化

### 症状
- 每次运行 `docker-deploy-v4.bat` 都显示 "主 API 密钥: 未配置"
- 用户选择 [1] 补充密钥后,输入密钥
- 显示 "✅ 密钥补充完成"
- 下次运行又显示"未配置",需要重新输入

### 诊断步骤

#### 步骤 1: 检查 .env 文件是否存在

```cmd
debug-env.bat
```

这个工具会检查:
- ✅ `BettaFish-main` 目录是否存在
- ✅ `.env` 文件是否存在
- ✅ `.env` 文件的完整内容
- ✅ 引擎密钥是否正确写入
- ✅ 其他密钥 (Tavily, Bocha, DB_PASSWORD)

#### 步骤 2: 查看诊断结果

**情况 A: 项目目录不存在**
```
❌ 项目目录不存在: C:\...\BettaFish-main
请先运行 download-project.bat 下载项目源码
```

**解决**: 运行 `download-project.bat` 下载源码

**情况 B: .env 文件不存在**
```
❌ .env 文件不存在
这是第一次运行,还没有生成 .env 文件
```

**原因**: 部署脚本在生成 .env 之前就失败退出了
**解决**: 先解决 Docker 镜像拉取问题 (见问题2)

**情况 C: .env 文件存在但密钥为空**
```
✅ .env 文件存在
❌ INSIGHT_ENGINE_API_KEY 未配置
❌ MEDIA_ENGINE_API_KEY 未配置
...
```

**原因**: `Generate-EnvFile` 函数生成 .env 时 `$mainKey` 变量为空
**解决**: 见下方"代码修复"

**情况 D: .env 文件存在且密钥有值**
```
✅ .env 文件存在
✅ INSIGHT_ENGINE_API_KEY = sk-SEQr8***
✅ MEDIA_ENGINE_API_KEY = sk-SEQr8***
...
```

**原因**: .env 正确,但读取逻辑有问题
**解决**: 见下方"代码修复"

### 可能的根本原因

#### 原因 1: 编码问题 ⚠️ 最可能

`docker-deploy-v4.ps1` 文件应该是 **UTF-8 with BOM** 编码 (因为没有 `#Requires` 指令),但可能被错误保存为 UTF-8 without BOM。

**验证**:
```powershell
$bytes = [System.IO.File]::ReadAllBytes("docker-deploy-v4.ps1")
if ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    Write-Host "✅ UTF-8 with BOM" -ForegroundColor Green
} else {
    Write-Host "❌ UTF-8 without BOM (错误!)" -ForegroundColor Red
}
```

**修复**:
```cmd
fix-all.bat
```

#### 原因 2: 变量作用域问题

`Generate-EnvFile` 函数中的 `$mainKey` 逻辑可能没有正确获取补充的密钥。

**当前代码** (Line 451-466):
```powershell
$mainKey = if ($APIKeys.ContainsKey('INSIGHT_ENGINE_API_KEY') -and $APIKeys['INSIGHT_ENGINE_API_KEY']) {
    $APIKeys['INSIGHT_ENGINE_API_KEY']
} elseif (...) {
    ...
}
```

**问题**: 如果所有条件都为 false, `$mainKey` = `$null`,生成的 .env 文件中所有引擎密钥都是空的!

**验证**: 运行 `debug-env.bat` 查看 .env 中的引擎密钥值

#### 原因 3: 文件路径问题

`$envFile = Join-Path $PROJECT_DIR ".env"` 生成的路径可能在读取和写入时不一致。

**验证**: 在 `debug-env.bat` 输出中检查路径

---

## 🔴 问题 2: Docker 镜像源持久化问题

### 症状
- 拉取 PostgreSQL 镜像时报错: `403 Forbidden` from `docker.1panel.live`
- 脚本自动清理 `daemon.json` 中的 `registry-mirrors` 配置
- 显示 "✅ 镜像源配置已清理 ✅ Docker 重启完成"
- 下次拉取仍然报错 403 或超时

### 用户当前配置

用户显示的 `daemon.json` 内容:
```json
{
  "builder": {
    "gc": {
      "defaultKeepStorage": "20GB",
      "enabled": true
    }
  },
  "experimental": false
}
```

**✅ 配置已清理** - 没有 `registry-mirrors`

但 Docker 仍然尝试使用 `docker.1panel.live`!

### 可能的原因

#### 原因 1: Docker Desktop 应用程序设置 ⭐ 最可能

Docker Desktop 可能在 GUI 设置中配置了镜像源,优先级高于 `daemon.json`。

**检查位置**:
1. 打开 Docker Desktop
2. Settings → Docker Engine
3. 查看右侧 JSON 配置

**如果看到**:
```json
{
  "registry-mirrors": [
    "https://docker.1panel.live"
  ],
  ...
}
```

**修复**:
1. 删除整个 `"registry-mirrors"` 部分
2. 点击 "Apply & Restart"
3. 等待 Docker 完全重启 (右下角图标稳定)

#### 原因 2: 多个配置文件位置

Windows Docker Desktop 可能在多个位置读取配置:
1. `%USERPROFILE%\.docker\daemon.json` ← 当前脚本检查这个
2. `%APPDATA%\Docker\daemon.json`
3. `%ProgramData%\Docker\config\daemon.json`
4. WSL2 Backend: `\\wsl$\docker-desktop-data\...`

**验证**: 运行以下 PowerShell 检查所有位置:
```powershell
$locations = @(
    "$env:USERPROFILE\.docker\daemon.json",
    "$env:APPDATA\Docker\daemon.json",
    "$env:ProgramData\Docker\config\daemon.json"
)

foreach ($path in $locations) {
    if (Test-Path $path) {
        Write-Host "找到配置: $path" -ForegroundColor Yellow
        $content = Get-Content $path -Raw
        if ($content -match 'docker\.1panel\.live') {
            Write-Host "❌ 包含无效镜像源!" -ForegroundColor Red
        } else {
            Write-Host "✅ 配置正常" -ForegroundColor Green
        }
    } else {
        Write-Host "不存在: $path" -ForegroundColor Gray
    }
}
```

#### 原因 3: Docker 没有真正重启

脚本使用的重启命令:
```powershell
Stop-Process -Name "Docker Desktop" -Force
Start-Process -FilePath $dockerExe -WindowStyle Hidden
```

可能导致:
- Docker Desktop 进程结束,但 Docker Engine 仍在运行
- 配置没有被重新加载

**更好的重启方法**:
```powershell
# 完全停止 Docker
Stop-Service -Name "com.docker.service" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "Docker Desktop" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 5

# 重新启动
Start-Process -FilePath $dockerExe -WindowStyle Hidden
Start-Sleep -Seconds 10

# 等待 Docker 就绪
$maxAttempts = 30
for ($i = 0; $i -lt $maxAttempts; $i++) {
    $info = docker info 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Docker 已就绪"
        break
    }
    Write-Host "等待 Docker 启动... ($i/$maxAttempts)"
    Start-Sleep -Seconds 2
}
```

#### 原因 4: 环境变量或代理设置

Docker 可能通过环境变量配置了镜像源:
- `DOCKER_REGISTRY_MIRROR`
- `HTTP_PROXY` / `HTTPS_PROXY`

**验证**:
```powershell
Get-ChildItem Env: | Where-Object { $_.Name -like '*DOCKER*' -or $_.Name -like '*PROXY*' }
```

### 推荐解决方案

#### 方案 A: 手动清理 Docker Desktop 设置 (推荐)

1. 打开 Docker Desktop
2. Settings → Docker Engine
3. 删除 `registry-mirrors` 配置
4. Apply & Restart
5. 等待 Docker 完全重启
6. 运行 `docker-deploy-v4.bat`

#### 方案 B: 绕过镜像源问题 - 使用 quick-fix 方法

用户之前的 `quick-fix.bat` 成功拉取了镜像,说明使用**明确指定的镜像源**可以绕过 Docker 配置。

**quick-fix.bat 的成功逻辑**:
```powershell
# 不依赖 Docker daemon 配置,直接从指定镜像源拉取
docker pull docker.m.daocloud.io/postgres:15
docker tag docker.m.daocloud.io/postgres:15 postgres:15

docker pull ghcr.nju.edu.cn/666ghj/bettafish:latest
docker tag ghcr.nju.edu.cn/666ghj/bettafish:latest ghcr.io/666ghj/bettafish:latest
```

**集成到 docker-deploy-v4.ps1**:
修改 `Manage-DockerImages` 函数 (第 618-654 行),使用相同策略。

#### 方案 C: 完全禁用 Docker 镜像源配置

创建一个工具强制清除所有位置的镜像源配置:
```cmd
fix-docker-mirrors.bat
```

这个工具已经创建,但需要增强:
1. 检查所有 3 个配置文件位置
2. 检查 Docker Desktop GUI 设置
3. 更彻底的 Docker 重启

---

## 📋 诊断检查清单

运行以下工具进行完整诊断:

### 1. 检查 API 密钥问题
```cmd
debug-env.bat
```

**预期输出 (正常)**:
```
✅ 项目目录存在
✅ .env 文件存在
✅ INSIGHT_ENGINE_API_KEY = sk-SEQr8***
✅ MEDIA_ENGINE_API_KEY = sk-SEQr8***
✅ TAVILY_API_KEY = tvl-***
✅ BOCHA_WEB_SEARCH_API_KEY = sk-***
✅ 主 API 密钥已配置
```

**预期输出 (异常)**:
```
✅ 项目目录存在
✅ .env 文件存在
❌ INSIGHT_ENGINE_API_KEY 未配置
❌ 主 API 密钥未配置
```

→ 如果异常,说明 `Generate-EnvFile` 函数有 bug

### 2. 检查 Docker 配置问题
```cmd
fix-docker-mirrors.bat
```

或手动检查:
1. 打开 Docker Desktop → Settings → Docker Engine
2. 查看是否有 `registry-mirrors` 配置
3. 如果有,删除并重启

### 3. 检查文件编码
```cmd
fix-all.bat
```

确保所有 PowerShell 脚本编码正确。

---

## 🔧 临时解决方案

在问题修复之前,使用以下步骤成功部署:

### 步骤 1: 下载项目源码
```cmd
download-project.bat
```

### 步骤 2: 手动清理 Docker 镜像源
1. 打开 Docker Desktop
2. Settings → Docker Engine
3. 删除 `registry-mirrors` (如果有)
4. Apply & Restart

### 步骤 3: 使用 quick-fix 拉取镜像
```cmd
quick-fix.bat
```

等待镜像拉取完成。

### 步骤 4: 手动创建 .env 文件

复制以下内容,保存为 `BettaFish-main\.env`:

```env
# ====================== BETTAFISH 相关 ======================
HOST=0.0.0.0
PORT=5000

# ====================== 数据库配置 ======================
DB_HOST=db
DB_PORT=5432
DB_USER=bettafish
DB_PASSWORD=bettafish_secure_1234567890
DB_NAME=bettafish
DB_CHARSET=utf8mb4
DB_DIALECT=postgresql

# ======================= LLM 相关 =======================
# Insight Agent（洞察引擎）
INSIGHT_ENGINE_API_KEY=YOUR_API_KEY_HERE
INSIGHT_ENGINE_BASE_URL=https://vibecodingapi.ai/v1
INSIGHT_ENGINE_MODEL_NAME=gpt-4o

# Media Agent（媒体引擎）
MEDIA_ENGINE_API_KEY=YOUR_API_KEY_HERE
MEDIA_ENGINE_BASE_URL=https://vibecodingapi.ai/v1
MEDIA_ENGINE_MODEL_NAME=gpt-4o

# Query Agent（查询引擎）
QUERY_ENGINE_API_KEY=YOUR_API_KEY_HERE
QUERY_ENGINE_BASE_URL=https://vibecodingapi.ai/v1
QUERY_ENGINE_MODEL_NAME=gpt-4o

# Report Agent（报告引擎）
REPORT_ENGINE_API_KEY=YOUR_API_KEY_HERE
REPORT_ENGINE_BASE_URL=https://vibecodingapi.ai/v1
REPORT_ENGINE_MODEL_NAME=gemini-2.5-pro

# MindSpider Agent（爬虫引擎）
MINDSPIDER_API_KEY=YOUR_API_KEY_HERE
MINDSPIDER_BASE_URL=https://vibecodingapi.ai/v1
MINDSPIDER_MODEL_NAME=deepseek-chat

# 论坛主持人
FORUM_HOST_API_KEY=YOUR_API_KEY_HERE
FORUM_HOST_BASE_URL=https://vibecodingapi.ai/v1
FORUM_HOST_MODEL_NAME=gpt-4o

# SQL Keyword Optimizer（关键词优化器）
KEYWORD_OPTIMIZER_API_KEY=YOUR_API_KEY_HERE
KEYWORD_OPTIMIZER_BASE_URL=https://vibecodingapi.ai/v1
KEYWORD_OPTIMIZER_MODEL_NAME=gpt-3.5-turbo

# ================== 网络工具配置 ====================
TAVILY_API_KEY=YOUR_TAVILY_KEY_HERE
BOCHA_BASE_URL=https://api.bochaai.com/v1/ai-search
BOCHA_WEB_SEARCH_API_KEY=YOUR_BOCHA_KEY_HERE
```

**替换以下内容**:
- `YOUR_API_KEY_HERE` → 你的主 API 密钥 (sk-SEQr8J9jDdsulnM12vUqTcoo67AEYhptdoD6R22cvk5sIxlc)
- `YOUR_TAVILY_KEY_HERE` → 你的 Tavily 密钥
- `YOUR_BOCHA_KEY_HERE` → 你的 Bocha 密钥

### 步骤 5: 手动启动容器

```cmd
cd BettaFish-main
docker-compose up -d
```

### 步骤 6: 验证部署

```cmd
docker ps
```

应该看到两个容器:
- `bettafish-main-app-1` (Running)
- `bettafish-main-db-1` (Running)

打开浏览器访问: http://localhost:5000

---

## 🔬 需要用户提供的信息

为了进一步诊断,请提供以下信息:

### 1. 运行 debug-env.bat 的完整输出

```cmd
debug-env.bat
```

复制完整输出。

### 2. Docker Desktop 设置截图

打开 Docker Desktop → Settings → Docker Engine,截图右侧 JSON 配置。

### 3. 检查所有 daemon.json 文件

运行以下 PowerShell 并提供输出:

```powershell
$locations = @(
    "$env:USERPROFILE\.docker\daemon.json",
    "$env:APPDATA\Docker\daemon.json",
    "$env:ProgramData\Docker\config\daemon.json"
)

foreach ($path in $locations) {
    Write-Host "检查: $path" -ForegroundColor Yellow
    if (Test-Path $path) {
        Write-Host "  ✅ 文件存在" -ForegroundColor Green
        $content = Get-Content $path -Raw
        Write-Host "  内容:" -ForegroundColor Cyan
        Write-Host $content -ForegroundColor Gray
    } else {
        Write-Host "  ❌ 文件不存在" -ForegroundColor Red
    }
    Write-Host ""
}
```

### 4. Docker info 输出

```cmd
docker info
```

查找 "Registry Mirrors" 部分。

---

## 📊 下一步行动

基于诊断结果,将采取以下修复措施:

### 修复 1: 增强 Generate-EnvFile 函数

添加调试日志和空值检查:
```powershell
# 获取主密钥时添加日志
Write-Host "DEBUG: 检查 INSIGHT_ENGINE_API_KEY..." -ForegroundColor Magenta
if ($APIKeys.ContainsKey('INSIGHT_ENGINE_API_KEY')) {
    Write-Host "DEBUG: 找到 INSIGHT_ENGINE_API_KEY" -ForegroundColor Magenta
    $mainKey = $APIKeys['INSIGHT_ENGINE_API_KEY']
} else {
    Write-Host "DEBUG: 未找到 INSIGHT_ENGINE_API_KEY" -ForegroundColor Magenta
}

if (-not $mainKey) {
    Write-Error "CRITICAL: 无法获取主 API 密钥! APIKeys 内容:"
    $APIKeys | Format-Table | Out-String | Write-Host
    throw "主 API 密钥为空"
}
```

### 修复 2: 增强 Docker 镜像源清理

修改 `fix-docker-mirrors.ps1`:
1. 检查所有 3 个配置位置
2. 更彻底的 Docker 重启
3. 验证重启后的配置

### 修复 3: 集成 quick-fix 逻辑

修改 `Manage-DockerImages` 函数,直接使用镜像源拉取:
```powershell
# PostgreSQL - 使用 DaoCloud 镜像
docker pull docker.m.daocloud.io/postgres:15
docker tag docker.m.daocloud.io/postgres:15 postgres:15

# BettaFish - 使用南京大学镜像
docker pull ghcr.nju.edu.cn/666ghj/bettafish:latest
docker tag ghcr.nju.edu.cn/666ghj/bettafish:latest ghcr.io/666ghj/bettafish:latest
```

---

**状态**: 等待用户提供诊断信息
**优先级**: P0 (阻塞部署)
**预计修复时间**: 提供信息后 30 分钟内
