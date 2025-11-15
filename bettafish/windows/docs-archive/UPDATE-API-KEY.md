# 🔑 如何更新 API 密钥

## 📝 说明

如果你需要修改或更新已配置的 API 密钥（例如示例密钥、测试密钥等），有以下几种方法：

---

## 方法 1: 直接编辑 .env 文件（最简单）

### 步骤 1: 找到 .env 文件

```
Windows-Version/
└── BettaFish-main/
    └── .env    ← 这个文件
```

完整路径：
```
C:\Users\12863\OneDrive\Downloads\BettaFish-Deployment-Kit\Windows-Version\BettaFish-main\.env
```

### 步骤 2: 用记事本打开并编辑

```powershell
# 用记事本打开
notepad C:\Users\12863\OneDrive\Downloads\BettaFish-Deployment-Kit\Windows-Version\BettaFish-main\.env

# 或者在当前目录
cd C:\Users\12863\OneDrive\Downloads\BettaFish-Deployment-Kit\Windows-Version\BettaFish-main
notepad .env
```

### 步骤 3: 修改 API Key

找到这一行：
```env
OPENAI_API_KEY=sk-SEQr8J9jDdsulnM12vUqTcoo67AEYhptdoD6R22cvk5sIxlc
```

修改为你的真实 API Key：
```env
OPENAI_API_KEY=sk-proj-your-real-api-key-here
```

### 步骤 4: 保存并关闭

- Ctrl+S 保存
- 关闭记事本

### 步骤 5: 重启服务（如果已部署）

```powershell
cd C:\Users\12863\OneDrive\Downloads\BettaFish-Deployment-Kit\Windows-Version\BettaFish-main

# 停止服务
docker-compose down

# 重新启动
docker-compose up -d
```

---

## 方法 2: 删除 .env 重新部署

如果你想完全重新配置：

### 步骤 1: 删除现有 .env 文件

```powershell
Remove-Item C:\Users\12863\OneDrive\Downloads\BettaFish-Deployment-Kit\Windows-Version\BettaFish-main\.env
```

### 步骤 2: 重新运行部署脚本

```cmd
cd C:\Users\12863\OneDrive\Downloads\BettaFish-Deployment-Kit\Windows-Version
docker-deploy.bat
```

脚本会重新询问你输入 API Key。

---

## 方法 3: 使用 PowerShell 快速修改

```powershell
cd C:\Users\12863\OneDrive\Downloads\BettaFish-Deployment-Kit\Windows-Version\BettaFish-main

# 读取现有配置
$envContent = Get-Content .env -Raw

# 替换 OpenAI API Key
$newKey = "sk-proj-your-real-api-key-here"
$envContent = $envContent -replace 'OPENAI_API_KEY=.*', "OPENAI_API_KEY=$newKey"

# 保存
$envContent | Out-File -FilePath .env -Encoding UTF8 -Force

Write-Host "API Key updated!" -ForegroundColor Green
```

---

## 📋 完整的 .env 文件示例

```env
# BettaFish 环境配置文件
# 自动生成于: 2025-11-15 14:30:00

# OpenAI API Configuration
OPENAI_API_KEY=sk-proj-your-real-openai-api-key-here

# Firecrawl API Configuration
FIRECRAWL_API_KEY=fc-your-real-firecrawl-api-key-here

# Database Configuration
POSTGRES_USER=bettafish
POSTGRES_PASSWORD=bettafish_secure_2024
POSTGRES_DB=bettafish_db
POSTGRES_HOST=postgres
POSTGRES_PORT=5432

# Application Configuration
APP_ENV=production
DEBUG=false
```

---

## 🔐 如何获取真实的 API Key

### OpenAI API Key

1. 访问：https://platform.openai.com/api-keys
2. 登录你的 OpenAI 账号
3. 点击 "Create new secret key"
4. 复制生成的密钥（以 `sk-proj-` 开头）
5. 粘贴到 `.env` 文件

### Firecrawl API Key（可选）

1. 访问：https://firecrawl.dev/
2. 注册/登录账号
3. 获取 API Key
4. 粘贴到 `.env` 文件

---

## ⚠️ 重要提示

### 1. 环境变量立即生效

修改 `.env` 文件后，需要**重启容器**才能生效：

```powershell
cd BettaFish-main
docker-compose restart
```

### 2. 不要提交 .env 文件到 Git

`.env` 文件包含敏感信息，应该被 `.gitignore` 排除。

### 3. 验证 API Key 是否生效

修改后，检查日志确认 API Key 正常工作：

```powershell
docker-compose logs -f bettafish
```

如果看到 API 调用成功的日志 = 配置正确。

---

## 🔍 常见问题

### Q: 修改 .env 后服务没有变化？

**A**: 需要重启容器：
```powershell
docker-compose restart
```

---

### Q: 找不到 .env 文件？

**A**: .env 是隐藏文件，在文件资源管理器中：
1. 打开文件夹：`BettaFish-main`
2. 查看 → 显示 → 显示隐藏的文件

或者用命令：
```powershell
Get-ChildItem -Force | Where-Object {$_.Name -eq ".env"}
```

---

### Q: .env 文件编码错误？

**A**: 必须使用 UTF-8 编码保存。使用记事本时：
- 文件 → 另存为
- 编码：UTF-8
- 保存

---

## 📝 快速修改模板

复制这段代码，修改后执行：

```powershell
# 设置你的真实 API Key
$YOUR_OPENAI_KEY = "sk-proj-xxxxx"  # ← 改这里
$YOUR_FIRECRAWL_KEY = ""            # ← 可选

# 自动更新 .env 文件
$envPath = "C:\Users\12863\OneDrive\Downloads\BettaFish-Deployment-Kit\Windows-Version\BettaFish-main\.env"
$envContent = Get-Content $envPath -Raw
$envContent = $envContent -replace 'OPENAI_API_KEY=.*', "OPENAI_API_KEY=$YOUR_OPENAI_KEY"
if ($YOUR_FIRECRAWL_KEY) {
    $envContent = $envContent -replace 'FIRECRAWL_API_KEY=.*', "FIRECRAWL_API_KEY=$YOUR_FIRECRAWL_KEY"
}
$envContent | Out-File -FilePath $envPath -Encoding UTF8 -Force

Write-Host "✅ API Keys updated!" -ForegroundColor Green
Write-Host "Next: Restart services with 'docker-compose restart'" -ForegroundColor Cyan
```

---

**更新**: 2025-11-15
**版本**: v3.8.4
