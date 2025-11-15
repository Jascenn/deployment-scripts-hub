# BettaFish 部署工具包 v2.0

[![Version](https://img.shields.io/badge/version-2.0-blue.svg)](https://github.com/666ghj/BettaFish)
[![Docker](https://img.shields.io/badge/docker-required-blue.svg)](https://www.docker.com/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

一键部署 BettaFish AI 助手，支持 macOS 和 Linux，内置 7 个 LLM 引擎和智能搜索功能。

---

## 🌟 特性

### v2.0 核心特性

- ⚡ **快速部署** - 使用预构建镜像，5 分钟完成部署
- 🤖 **智能化** - 自动镜像源选择、端口冲突修复
- 🧹 **自动清理** - 智能清理旧镜像，节省 5-21 GB 空间
- 📦 **条件备份** - 仅在配置变化时备份，避免冗余
- 🔧 **易维护** - 统一的备份和日志管理系统
- 🌐 **7 引擎支持** - Insight、Media、Query、Code、Main、DeepSeek、OpenAI

---

## 📋 快速开始

### 系统要求

- **操作系统**: macOS 或 Linux
- **内存**: 8GB+ 推荐
- **磁盘空间**: 20GB+ 可用
- **软件**: Docker Desktop 或 Docker Engine + Docker Compose v2.0+

### API 密钥准备

| 密钥 | 必需性 | 获取地址 |
|------|--------|---------|
| 主 API 密钥 | ✅ 必填 | [VibeAI](https://vibecodingapi.ai/) |
| Tavily 搜索 | ⚠️ 推荐 | [Tavily](https://tavily.com/) |
| Bocha 搜索 | ⚠️ 可选 | [Bocha](https://bocha.ai/) |

### 三步部署

#### 1. 下载并解压

```bash
cd ~/Downloads
unzip BettaFish-Deployment-Kit.zip
cd BettaFish-Deployment-Kit
```

#### 2. 运行部署脚本

```bash
chmod +x docker-deploy.sh
./docker-deploy.sh
```

#### 3. 按提示输入 API 密钥

脚本会自动完成：
- ✅ 环境检测
- ✅ 镜像源测速
- ✅ 镜像拉取
- ✅ 容器启动
- ✅ 健康检查

### 部署完成

```
========================================
🎉 BettaFish 部署完成！
========================================

🌐 服务访问地址:

  ● BettaFish 主服务:       http://localhost:5000
  ● Insight Engine:        http://localhost:8501
  ● Media Engine:          http://localhost:8502
  ● Query Engine:          http://localhost:8503
  ● 数据库服务:            localhost:5432
```

在浏览器访问 `http://localhost:5000` 即可开始使用！

---

## 📚 文档导航

### 用户文档

| 文档 | 说明 | 适用对象 |
|------|------|---------|
| [快速开始指南](guides/快速开始指南.md) | 5 分钟快速部署教程 | 所有用户 |
| [故障排查指南](guides/故障排查指南.md) | 常见问题解决方案 | 所有用户 |

### 技术文档

| 文档 | 说明 | 适用对象 |
|------|------|---------|
| [技术文档](technical/技术文档.md) | 详细技术说明和高级配置 | 开发者 |
| [核心架构](technical/核心架构.md) | 文件结构和系统架构 | 开发者 |

### 版本文档

| 文档 | 说明 |
|------|------|
| [v2.0 更新汇总](../v2.0更新汇总.md) | 所有 v2.0 新特性 |
| [条件备份说明](../条件备份实现说明.md) | 智能备份机制详解 |

---

## 🚀 v2.0 亮点

### 1. 预构建镜像部署

**v1.x**: 本地构建 (15-20 分钟)
```bash
docker build -t bettafish:latest .
```

**v2.0**: 预构建镜像 (5-8 分钟)
```bash
docker-compose pull
docker-compose up -d
```

**优势**:
- ⚡ 部署时间减少 60%
- 💾 节省本地磁盘空间
- 🔄 官方维护的稳定镜像

---

### 2. 智能镜像源选择

自动测试网络速度，选择最快的镜像源：

```
ℹ️  测试镜像源网络连接速度...

  • 官方镜像源:      180ms
  • 南京大学镜像:     450ms

✅ 选择最快的镜像源: 官方镜像源 (180ms)
```

**支持的镜像源**:
- 🌍 官方源: `ghcr.io`
- 🇨🇳 国内镜像: `ghcr.nju.edu.cn`

---

### 3. 自动镜像清理

自动检测并清理旧的/未使用的 Docker 镜像：

```
ℹ️  检测多余镜像...
⚠️  检测到 3 个可清理的旧镜像

  • bettafish:latest (4.89GB)
  • postgres:15-alpine (378MB)
  • python:3.11-slim (211MB)

ℹ️  正在清理旧镜像...
  ✓ 已删除: bettafish:latest
  ✓ 已删除: postgres:15-alpine
  ✓ 已删除: python:3.11-slim

✅ 已清理 3 个旧镜像
```

**可节省**: 5-21 GB 磁盘空间

---

### 4. 端口冲突自动修复

检测端口占用，自动查找可用端口并修复配置：

```
⚠️  默认端口 5000 已被占用
ℹ️  正在查找可用端口 (5001-5010)...
✅ 找到可用端口: 5001
✅ 端口配置已更新: 5000 → 5001
```

**特点**:
- 🔍 自动检测端口 5001-5010
- 🔧 自动修改配置
- 📦 自动备份原配置
- ✅ 无需用户干预

---

### 5. 完整服务地址显示

部署完成后显示所有 5 个服务的访问地址：

```
🌐 服务访问地址:

  ● BettaFish 主服务:       http://localhost:5001
  ● Insight Engine:        http://localhost:8501
  ● Media Engine:          http://localhost:8502
  ● Query Engine:          http://localhost:8503
  ● 数据库服务:            localhost:5432
```

---

### 6. 统一备份系统

集中管理所有备份文件和日志：

```
BettaFish-Deployment-Kit/
├── backups/                    # 备份目录
│   ├── env_backup_20250114_143025.env
│   ├── docker-compose_backup_20250114_143030.yml
│   └── docker-compose_port_5001_20250114_143035.yml
│
└── logs/                       # 日志目录
    ├── deploy_20250114_143020.log
    ├── deploy_20250114_150000.log
    └── deploy_20250114_180000.log
```

**特点**:
- 📂 统一存储位置
- 🕐 时间戳命名
- 💡 条件备份（仅在变化时）
- 🔍 易于追溯

---

### 7. 条件备份机制

仅在配置实际改变时创建备份，避免冗余：

#### .env 配置备份
**触发条件**:
- ✅ 用户重新输入配置
- ✅ Bocha API 密钥变化
- ❌ 使用现有配置且无修改

#### docker-compose.yml 镜像源备份
**触发条件**:
- ✅ 实际切换镜像源
- ❌ 已是最优镜像源

#### 端口配置备份
**触发条件**:
- ✅ 端口冲突并修改
- ❌ 端口可用无需修改

**效率提升**: 节省约 50% 的备份文件

---

## 📊 v1.x vs v2.0 对比

| 功能 | v1.x | v2.0 | 改进 |
|------|------|------|------|
| 部署方式 | 本地构建 | 预构建镜像 | ⚡ 快 3-5 倍 |
| 部署时间 | 15-20 分钟 | 5-8 分钟 | ⚡ 60% ↓ |
| 镜像源 | 手动配置 | 自动测速选择 | 🤖 智能化 |
| 旧镜像清理 | 手动 | 自动清理 | 💾 节省 5-21 GB |
| 端口冲突 | 手动解决 | 自动修复 | ✅ 无需干预 |
| 服务地址 | 仅主服务 | 全部 5 个 | 📍 更完整 |
| Base URL | 需要输入 | 固定值 | ⏭️ 更简单 |
| 备份管理 | 分散存储 | 集中管理 | 📂 更整洁 |
| 备份策略 | 每次都备份 | 条件备份 | 💡 更智能 |
| 部署日志 | 无 | 完整记录 | 🔍 可追溯 |

---

## 🎯 使用场景

### 场景 1: 首次部署

```bash
./docker-deploy.sh
# 按提示输入 API 密钥
# 等待 5-8 分钟
# 访问 http://localhost:5000
```

### 场景 2: 更新到最新版本

```bash
./docker-deploy.sh
# 选择使用现有配置 (Y)
# 自动拉取最新镜像
# 自动清理旧镜像
```

### 场景 3: 修改 API 密钥

```bash
./docker-deploy.sh
# 选择重新输入配置 (n)
# 输入新的 API 密钥
# 自动备份旧配置
```

### 场景 4: 端口冲突

```bash
./docker-deploy.sh
# 脚本自动检测端口 5000 被占用
# 自动切换到 5001
# 无需手动操作
```

---

## 🔧 日常使用

### 启动服务

```bash
cd BettaFish-main
docker-compose up -d
```

### 停止服务

```bash
cd BettaFish-main
docker-compose stop
```

### 查看状态

```bash
cd BettaFish-main
docker-compose ps
```

### 查看日志

```bash
cd BettaFish-main

# 主服务日志
docker-compose logs -f bettafish

# 数据库日志
docker-compose logs -f db
```

### 重启服务

```bash
cd BettaFish-main
docker-compose restart
```

---

## 🗑️ 卸载

### 停止并删除容器（保留数据）

```bash
cd BettaFish-main
docker-compose down
```

### 完全卸载（包括数据）

```bash
cd BettaFish-main

# 停止并删除容器和数据卷
docker-compose down -v

# 删除镜像
docker rmi ghcr.io/666ghj/bettafish:latest
docker rmi postgres:15

# 删除部署工具包
cd ..
rm -rf BettaFish-Deployment-Kit
```

---

## 🐛 故障排查

### 常见问题

#### 1. Docker 未安装
```bash
# macOS
# 下载: https://www.docker.com/products/docker-desktop

# Linux
sudo apt install docker.io docker-compose
```

#### 2. 端口被占用
脚本会自动检测并修复，无需手动处理

#### 3. 镜像下载缓慢
脚本会自动选择最快的镜像源

#### 4. 服务无法访问
```bash
# 检查容器状态
docker-compose ps

# 查看日志
docker-compose logs bettafish
```

更多问题请查看 [故障排查指南](guides/故障排查指南.md)

---

## 📞 获取帮助

### 文档资源

- [快速开始指南](guides/快速开始指南.md) - 详细部署步骤
- [技术文档](technical/技术文档.md) - 技术细节和高级配置
- [故障排查指南](guides/故障排查指南.md) - 问题解决方案
- [核心架构](technical/核心架构.md) - 系统架构和文件结构

### 社区支持

- **GitHub Issues**: [报告问题](https://github.com/666ghj/BettaFish/issues)
- **讨论区**: [GitHub Discussions](https://github.com/666ghj/BettaFish/discussions)

### 查看日志

部署日志位置:
```
BettaFish-Deployment-Kit/logs/deploy_YYYYMMDD_HHMMSS.log
```

配置备份位置:
```
BettaFish-Deployment-Kit/backups/
```

---

## 🏗️ 技术架构

### 系统组件

```
┌─────────────────────────────────────┐
│         用户浏览器                   │
└─────────────────────────────────────┘
           │
    http://localhost:5000
           │
┌─────────────────────────────────────┐
│    Docker Compose                   │
│  ┌───────────────────────────────┐  │
│  │  bettafish (主容器)           │  │
│  │  ├── Flask 后端               │  │
│  │  ├── 7 个 LLM 引擎            │  │
│  │  └── 3 个 Streamlit UI        │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │  bettafish-db (数据库)        │  │
│  │  └── PostgreSQL 15            │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

### 7 个 LLM 引擎

1. **Insight Engine** - 洞察分析 (Streamlit UI: 8501)
2. **Media Engine** - 媒体处理 (Streamlit UI: 8502)
3. **Query Engine** - 查询搜索 (Streamlit UI: 8503)
4. **Code Engine** - 代码生成
5. **Main Agent** - 主代理
6. **DeepSeek Agent** - DeepSeek 引擎
7. **OpenAI Agent** - OpenAI 引擎

所有引擎使用统一的 API 密钥和 Base URL (`https://vibecodingapi.ai/v1`)

---

## 🔐 安全性

### 敏感信息保护

- ✅ `.env` 文件不会提交到版本控制
- ✅ API 密钥加密存储
- ✅ 数据库密码动态生成
- ✅ 备份文件自动加入 `.gitignore`

### 网络安全

- 🔒 容器间通过内部网络通信
- 🔒 数据库默认仅容器内访问
- 🔒 支持配置防火墙规则

---

## 📈 性能优化

### 资源使用

| 组件 | CPU | 内存 | 磁盘 |
|------|-----|------|------|
| 主容器 | 2-4 核 | 2-4 GB | 16 GB |
| 数据库 | 1 核 | 1-2 GB | 5 GB |
| **总计** | **3-5 核** | **3-6 GB** | **21 GB** |

### 优化建议

1. **增加资源限制**: 编辑 `docker-compose.yml` 调整 CPU 和内存
2. **定期清理**: 运行脚本自动清理旧镜像
3. **数据库优化**: 定期执行 `VACUUM` 和 `ANALYZE`

---

## 🛠️ 高级配置

### 自定义端口

```yaml
# 编辑 docker-compose.yml
services:
  bettafish:
    ports:
      - "8080:5000"  # 修改主服务端口
```

### 自定义 Base URL

```bash
# 编辑 .env
vim BettaFish-main/.env

# 修改引擎的 BASE_URL
INSIGHT_ENGINE_BASE_URL=https://api.openai.com/v1

# 重启服务
docker-compose restart bettafish
```

### 使用不同模型

```bash
# 编辑 .env
INSIGHT_ENGINE_MODEL_NAME=gpt-4-turbo
MEDIA_ENGINE_MODEL_NAME=gpt-4o-mini

# 重启服务
docker-compose restart bettafish
```

更多高级配置请查看 [技术文档](technical/技术文档.md)

---

## 📝 更新日志

### v2.0 (2025-01-14)

**重大更新**:
- ✨ 采用预构建镜像，部署时间减少 60%
- ✨ 智能镜像源选择（自动测速）
- ✨ 自动镜像清理（节省 5-21 GB）
- ✨ 端口冲突自动修复
- ✨ 统一备份和日志系统
- ✨ 条件备份机制（仅在变化时）
- ✨ 完整服务地址显示
- ✨ Base URL 固定配置
- 🐛 修复 .env 目录问题
- 🐛 修复备份逻辑问题

### v1.x

- 基础本地构建部署
- 手动配置管理

---

## 🤝 贡献

欢迎贡献代码和文档！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

---

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

---

## 🙏 致谢

- [BettaFish 团队](https://github.com/666ghj/BettaFish) - 核心应用开发
- [VibeAI](https://vibecodingapi.ai/) - LLM API 服务
- [Docker](https://www.docker.com/) - 容器化平台
- [PostgreSQL](https://www.postgresql.org/) - 数据库
- [Streamlit](https://streamlit.io/) - UI 框架

---

## 🔗 相关链接

- **主项目**: [BettaFish GitHub](https://github.com/666ghj/BettaFish)
- **官方文档**: [BettaFish Docs](https://github.com/666ghj/BettaFish/wiki)
- **问题反馈**: [GitHub Issues](https://github.com/666ghj/BettaFish/issues)
- **社区讨论**: [GitHub Discussions](https://github.com/666ghj/BettaFish/discussions)

---

**部署工具版本**: v2.0
**最后更新**: 2025-01-14
**维护者**: BettaFish 部署工具开发团队

---

**祝您使用愉快！如有问题请查阅文档或联系我们。**
