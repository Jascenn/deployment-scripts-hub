# BettaFish 部署工具

> 🐟 基于 Docker 的 AI 对话系统 - 一键部署工具包

---

## 🚀 一键部署

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/deployment-scripts-hub/main/bettafish/smart-deploy.sh | bash
```

**就这么简单！** 5-8 分钟后访问 http://localhost:8501

---

## 📋 目录

- [快速开始](#-快速开始)
- [使用参数](#-使用参数)
- [前置要求](#-前置要求)
- [部署方式](#-部署方式)
- [高级配置](#-高级配置)
- [问题排查](#-问题排查)
- [版本历史](#-版本历史)

---

## 🎯 快速开始

### 方式 1: 一键部署（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/deployment-scripts-hub/main/bettafish/smart-deploy.sh | bash
```

### 方式 2: 使用代理

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/deployment-scripts-hub/main/bettafish/smart-deploy.sh | bash -s -- --proxy http://127.0.0.1:7890
```

### 方式 3: 最小化部署

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/deployment-scripts-hub/main/bettafish/smart-deploy.sh | bash -s -- --minimal
```

### 方式 4: 从 Release 下载

```bash
# 下载完整包
curl -fsSL https://github.com/YOUR_USERNAME/deployment-scripts-hub/releases/download/bettafish-v2.1/BettaFish-Deployment-Kit.tar.gz -o bettafish.tar.gz

# 解压并部署
tar -xzf bettafish.tar.gz
cd BettaFish-Deployment-Kit
./smart-deploy.sh
```

---

## 🛠️ 使用参数

### 所有支持的参数

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/deployment-scripts-hub/main/bettafish/smart-deploy.sh | bash -s -- [选项]
```

| 参数 | 说明 | 示例 |
|------|------|------|
| `--proxy PROXY` | 设置代理 | `--proxy http://127.0.0.1:7890` |
| `--minimal` | 使用最小核心包（3MB） | `--minimal` |
| `--dir DIR` | 指定部署目录 | `--dir ~/bettafish` |
| `--url URL` | 指定下载地址 | `--url https://custom-url.com` |
| `--skip-env-check` | 跳过环境检查 | `--skip-env-check` |
| `--help` | 显示帮助信息 | `--help` |

### 组合示例

```bash
# 使用代理 + 最小包 + 指定目录
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/deployment-scripts-hub/main/bettafish/smart-deploy.sh | bash -s -- \
  --proxy http://127.0.0.1:7890 \
  --minimal \
  --dir ~/my-bettafish
```

---

## ✅ 前置要求

### 必需

- **Docker Desktop** (macOS/Windows) 或 **Docker Engine** (Linux)
  - 下载：https://www.docker.com/products/docker-desktop
  - Docker 必须正在运行

### 系统要求

| 项目 | 最低要求 | 推荐配置 |
|------|---------|---------|
| **CPU** | 2 核 | 4 核+ |
| **内存** | 4GB | 8GB+ |
| **磁盘** | 5GB | 10GB+ |
| **系统** | macOS 10.14+ / Ubuntu 18.04+ / Windows 10+ | 最新版本 |

### 网络要求

- 稳定的网络连接
- 需要访问 ghcr.io（GitHub Container Registry）
- 国内网络建议使用代理

---

## 📦 部署方式

### 方式对比

| 方式 | 下载大小 | 部署时间 | 包含内容 | 推荐场景 |
|------|---------|---------|---------|---------|
| **完整包** | ~10MB | 5-8分钟 | 脚本+文档+工具 | 首次部署 |
| **最小包** | ~3MB | 3-5分钟 | 仅核心文件 | 快速部署 |
| **从 Release** | ~10MB | 5-8分钟 | 完整包 | 离线部署 |

### 网络环境

脚本会自动检测网络环境：
- ✅ 国际网络 → 使用 GitHub
- ✅ 国内网络 → 自动切换到 Gitee 镜像

---

## 🔧 高级配置

### 1. 配置 API 密钥

部署完成后，需要配置至少一个 LLM API：

```bash
cd BettaFish-main

# 复制配置模板
cp .env.example .env

# 编辑配置文件
nano .env
```

**支持的 API**：
- OpenAI API
- Azure OpenAI
- Anthropic Claude
- 其他兼容 OpenAI 的 API

### 2. 自定义端口

默认端口：`8501`

修改端口：
```bash
# 编辑 docker-compose.yml
cd BettaFish-main
nano docker-compose.yml

# 修改 ports 配置
ports:
  - "8888:8501"  # 改为 8888

# 重启
docker-compose down
docker-compose up -d
```

### 3. 持久化数据

数据存储在 Docker 卷中：

```bash
# 查看卷
docker volume ls | grep bettafish

# 备份数据
docker run --rm -v bettafish_data:/data -v $(pwd):/backup alpine tar czf /backup/bettafish-backup.tar.gz /data

# 恢复数据
docker run --rm -v bettafish_data:/data -v $(pwd):/backup alpine tar xzf /backup/bettafish-backup.tar.gz -C /
```

### 4. 代理配置

#### Clash
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/deployment-scripts-hub/main/bettafish/smart-deploy.sh | bash -s -- --proxy http://127.0.0.1:7890
```

#### v2rayN
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/deployment-scripts-hub/main/bettafish/smart-deploy.sh | bash -s -- --proxy http://127.0.0.1:10809
```

#### Shadowsocks
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/deployment-scripts-hub/main/bettafish/smart-deploy.sh | bash -s -- --proxy socks5://127.0.0.1:1080
```

更多配置：[docs/advanced-config.md](docs/advanced-config.md)

---

## 🐛 问题排查

### 常见问题

#### 1. Docker 未运行

**错误**：`Cannot connect to the Docker daemon`

**解决**：
```bash
# macOS/Windows
启动 Docker Desktop

# Linux
sudo systemctl start docker
```

#### 2. 端口被占用

**错误**：`Bind for 0.0.0.0:8501 failed: port is already allocated`

**解决**：
```bash
# 查看占用进程
lsof -i :8501

# 停止占用进程或修改端口（见上方"自定义端口"）
```

#### 3. 网络超时

**错误**：`Failed to pull image` 或 `Connection timeout`

**解决**：
```bash
# 使用代理
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/deployment-scripts-hub/main/bettafish/smart-deploy.sh | bash -s -- --proxy http://127.0.0.1:7890

# 或配置 Docker 镜像加速器（国内）
# 见 docs/troubleshooting.md
```

#### 4. 权限问题（Linux）

**错误**：`Permission denied`

**解决**：
```bash
# 添加用户到 docker 组
sudo usermod -aG docker $USER

# 重新登录生效
```

更多问题：[docs/troubleshooting.md](docs/troubleshooting.md)

---

## 📚 详细文档

- [快速开始指南](docs/quick-start.md) - 5 分钟上手
- [高级配置](docs/advanced-config.md) - API、端口、数据备份
- [问题排查](docs/troubleshooting.md) - 常见问题和解决方案
- [开发指南](docs/development.md) - 二次开发和自定义
- [更新日志](CHANGELOG.md) - 版本变更历史

---

## 🔄 常用命令

### 启动/停止

```bash
cd BettaFish-main

# 启动
docker-compose up -d

# 停止
docker-compose down

# 重启
docker-compose restart

# 查看状态
docker-compose ps
```

### 查看日志

```bash
# 查看所有日志
docker-compose logs

# 实时查看
docker-compose logs -f

# 查看最近 100 行
docker-compose logs --tail 100
```

### 更新

```bash
cd BettaFish-main

# 拉取最新镜像
docker-compose pull

# 重新启动
docker-compose up -d
```

### 清理

```bash
# 停止并删除容器
docker-compose down

# 同时删除数据卷（⚠️ 会清除所有数据）
docker-compose down -v

# 清理未使用的镜像
docker image prune -a
```

---

## 📊 版本历史

### v2.1 (2025-01-14) - 当前版本

**新功能**：
- ✨ 智能代理配置
- ✨ 网络环境自动检测
- ✨ 镜像清理用户确认

**优化**：
- 🔧 修复 ANSI 颜色显示
- 🔧 优化镜像清理逻辑
- 📚 更新可视化文档

### v2.0 (2025-01-13)

**新功能**：
- ✨ Docker 镜像源选择
- ✨ 智能端口检测
- ✨ 进度显示优化

### v1.0 (2025-01-12)

- 🎉 初始版本

完整变更：[CHANGELOG.md](CHANGELOG.md)

---

## 🔗 相关链接

- **官方项目**: https://github.com/666ghj/BettaFish
- **本脚本仓库**: https://github.com/YOUR_USERNAME/deployment-scripts-hub
- **问题反馈**: https://github.com/YOUR_USERNAME/deployment-scripts-hub/issues
- **讨论区**: https://github.com/YOUR_USERNAME/deployment-scripts-hub/discussions

---

## 📄 许可证

本部署脚本采用 MIT License。

BettaFish 项目本身的许可证请查看：https://github.com/666ghj/BettaFish

---

## 🙏 鸣谢

- **BettaFish 项目**: https://github.com/666ghj/BettaFish
- 所有贡献者和用户

---

## 📞 支持

遇到问题？

1. 查看 [问题排查文档](docs/troubleshooting.md)
2. 搜索 [Issues](https://github.com/YOUR_USERNAME/deployment-scripts-hub/issues)
3. 创建新 [Issue](https://github.com/YOUR_USERNAME/deployment-scripts-hub/issues/new)
4. 加入 [讨论区](https://github.com/YOUR_USERNAME/deployment-scripts-hub/discussions)

---

**维护者**: Your Name
**最后更新**: 2025-01-14
**状态**: ✅ 积极维护中
