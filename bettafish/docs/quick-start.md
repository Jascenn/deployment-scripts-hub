# BettaFish 快速开始指南

> ⏱️ 5 分钟快速部署 BettaFish AI 对话系统

---

## 前置条件检查

在开始之前，确保：

- ✅ 已安装 Docker Desktop（或 Docker Engine）
- ✅ Docker 正在运行
- ✅ 网络连接正常

**检查方法**：

```bash
# 检查 Docker 版本
docker --version
# 应输出：Docker version 20.x.x 或更高

# 检查 Docker 是否运行
docker ps
# 应正常显示容器列表（可以为空）
```

---

## 方式 1: 一键部署（最简单）

### 步骤 1: 运行部署命令

```bash
curl -fsSL https://raw.githubusercontent.com/Jascenn/deployment-scripts-hub/main/bettafish/smart-deploy.sh | bash
```

### 步骤 2: 等待完成

脚本会自动：
1. 检测网络环境
2. 下载部署包
3. 解压文件
4. 拉取 Docker 镜像
5. 启动服务

**总耗时**: 5-8 分钟（取决于网络速度）

### 步骤 3: 访问应用

部署完成后，打开浏览器访问：

```
http://localhost:8501
```

---

## 方式 2: 使用代理（国内用户推荐）

如果您在国内，访问 GitHub/ghcr.io 较慢，可以使用代理：

### Clash 用户

```bash
curl -fsSL https://raw.githubusercontent.com/Jascenn/deployment-scripts-hub/main/bettafish/smart-deploy.sh | bash -s -- --proxy http://127.0.0.1:7890
```

### v2rayN 用户

```bash
curl -fsSL https://raw.githubusercontent.com/Jascenn/deployment-scripts-hub/main/bettafish/smart-deploy.sh | bash -s -- --proxy http://127.0.0.1:10809
```

### 自定义代理

```bash
curl -fsSL https://raw.githubusercontent.com/Jascenn/deployment-scripts-hub/main/bettafish/smart-deploy.sh | bash -s -- --proxy http://YOUR_PROXY_HOST:PORT
```

---

## 方式 3: 最小化部署（最快）

如果您不需要文档和辅助工具，可以使用最小包：

```bash
curl -fsSL https://raw.githubusercontent.com/Jascenn/deployment-scripts-hub/main/bettafish/smart-deploy.sh | bash -s -- --minimal
```

**优点**：
- 下载更小（3MB vs 10MB）
- 部署更快（3-5 分钟）

**缺点**：
- 不包含可视化文档
- 不包含离线部署工具

---

## 配置 API 密钥

部署完成后，需要配置至少一个 LLM API 才能使用。

### 步骤 1: 进入项目目录

```bash
# 如果使用默认部署位置
cd /tmp/bettafish-deploy-*/BettaFish-Deployment-Kit*/BettaFish-main

# 如果指定了目录（例如 --dir ~/bettafish）
cd ~/bettafish/BettaFish-main
```

### 步骤 2: 复制配置模板

```bash
cp .env.example .env
```

### 步骤 3: 编辑配置文件

```bash
nano .env
# 或使用其他编辑器
vim .env
code .env
```

### 步骤 4: 填入 API 密钥

找到以下配置项，填入您的 API 密钥：

```bash
# OpenAI (推荐)
OPENAI_API_KEY=sk-your-openai-key-here

# 或 Azure OpenAI
AZURE_OPENAI_API_KEY=your-azure-key
AZURE_OPENAI_ENDPOINT=https://your-endpoint.openai.azure.com/

# 或 Anthropic Claude
ANTHROPIC_API_KEY=your-anthropic-key

# 或其他兼容 OpenAI 的 API
OPENAI_API_BASE=https://api.example.com/v1
OPENAI_API_KEY=your-custom-key
```

**至少配置一个 API** 即可启动使用。

### 步骤 5: 重启服务

```bash
docker-compose restart
```

### 步骤 6: 访问应用

```
http://localhost:8501
```

---

## 如何获取 API 密钥？

### OpenAI API

1. 访问：https://platform.openai.com/api-keys
2. 登录/注册账号
3. 点击 "Create new secret key"
4. 复制密钥（格式：`sk-...`）

**费用**: 按使用量付费，新用户有免费额度

### Azure OpenAI

1. 访问：https://portal.azure.com
2. 搜索 "Azure OpenAI Service"
3. 创建资源
4. 获取密钥和端点

**费用**: 按使用量付费

### Anthropic Claude

1. 访问：https://console.anthropic.com/
2. 登录/注册账号
3. 创建 API 密钥
4. 复制密钥

**费用**: 按使用量付费

---

## 验证部署

### 1. 检查容器状态

```bash
docker ps
```

应该看到类似输出：

```
CONTAINER ID   IMAGE                              STATUS         PORTS
abc123def456   ghcr.io/666ghj/bettafish:latest   Up 2 minutes   0.0.0.0:8501->8501/tcp
```

### 2. 检查日志

```bash
cd BettaFish-main
docker-compose logs
```

应该看到类似：

```
bettafish | Streamlit app is running on port 8501
bettafish | You can now view your Streamlit app in your browser
```

### 3. 访问应用

打开浏览器访问：http://localhost:8501

应该看到 BettaFish 界面。

---

## 下一步

恭喜！您已成功部署 BettaFish。

接下来您可以：

- 📚 阅读 [高级配置](advanced-config.md) 了解更多配置选项
- 🔧 自定义端口、数据持久化等
- 🤖 开始使用 AI 对话功能
- 📖 查看官方文档：https://github.com/666ghj/BettaFish

---

## 遇到问题？

- 查看 [问题排查文档](troubleshooting.md)
- 搜索 [Issues](https://github.com/Jascenn/deployment-scripts-hub/issues)
- 创建新问题

---

**预计完成时间**: ⏱️ 5-10 分钟
**难度**: ⭐ 简单
**最后更新**: 2025-01-14
