# BettaFish Windows 部署工具 v4.0.3

> 一键部署 BettaFish 舆情分析系统（Windows 版本）

[![版本](https://img.shields.io/badge/版本-v4.0.3-blue.svg)](https://github.com/666ghj/BettaFish)
[![状态](https://img.shields.io/badge/状态-稳定-green.svg)]()
[![平台](https://img.shields.io/badge/平台-Windows-lightgrey.svg)]()

---

## 🚀 快速开始

### 三步完成部署

```cmd
1. 确保 Docker Desktop 正在运行
2. 双击运行 docker-deploy-v4.bat
3. 按提示输入 API 密钥
```

就这么简单！✅

部署完成后，浏览器会自动打开 http://localhost:5000

---

## ✨ v4.0.3 核心特性

### 🎯 彻底解决镜像拉取问题

- ✅ 自动使用国内镜像加速源（DaoCloud / 南京大学）
- ✅ 绕过 Docker 配置的 `docker.1panel.live` 拦截
- ✅ 三级回退策略：DaoCloud → NJU → 官方源
- ✅ 无需手动清理 Docker 配置

### 🔧 完善的工具体系

| 工具 | 功能 | 使用场景 |
|------|------|----------|
| **docker-deploy-v4.bat** | 一键完整部署 | 首选工具 ⭐ |
| **debug-env.bat** | API 密钥诊断 | 密钥不持久时 |
| **diagnose.bat** | 系统全面诊断 | 遇到任何问题 |
| **fix-docker-mirrors.bat** | 镜像源修复 | 403 错误时 |
| **quick-fix.bat** | 单独拉取镜像 | 提前准备镜像 |

### 📚 完整的文档体系

| 文档 | 内容 | 适用对象 |
|------|------|----------|
| [使用指南](使用指南-v4.0.3.txt) | 完整使用说明 | 所有用户 |
| [快速修复指南](快速修复指南.txt) | 快速参考卡 | 遇到问题时 |
| [更新说明](v4.0.3-更新说明.md) | 技术更新详情 | 技术用户 |
| [问题修复说明](问题修复说明.md) | 问题诊断指南 | 故障排查 |

---

## 🎬 使用演示

### 首次部署流程

```
PS> .\docker-deploy-v4.bat

========================================
  BettaFish Docker 部署工具 v4.0
========================================

✅ Docker Desktop 正在运行

========================================
  步骤 1/7: 检查项目源码
========================================

✅ 项目源码已就绪: BettaFish-main

========================================
  步骤 3/7: API 密钥配置
========================================

ℹ️  配置 API 密钥

配置 API 密钥
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

主 API 密钥: sk-SEQr8J9jDdsu...
Tavily API 密钥: tvl-xxx...
Bocha API 密钥: sk-xxx...

========================================
  步骤 5/7: 镜像源选择与 Docker 镜像拉取
========================================

ℹ️  检查 Docker 镜像...

ℹ️  正在拉取 PostgreSQL 镜像...
ℹ️  尝试使用 DaoCloud 镜像加速源...

15: Pulling from postgres
891b5a61c527: Pull complete
4dc908580fc7: Pull complete
f8780632cce8: Pull complete
78c29b10a6ea: Pull complete
83e930c50688: Pull complete
5d3e627a217e: Pull complete
Digest: sha256:ec886...
Status: Downloaded newer image

ℹ️  重新标记为 postgres:15...
✅ PostgreSQL 镜像拉取成功 (DaoCloud 加速)

...

========================================
  部署完成！
========================================

🎉 BettaFish 已成功部署！

访问地址: http://localhost:5000
```

---

## 📦 安装要求

### 系统要求

- **操作系统**: Windows 10/11 (64-bit)
- **PowerShell**: 5.1 或更高版本
- **Docker Desktop**: 最新版本
- **内存**: 建议 8GB 以上
- **磁盘**: 至少 20GB 可用空间

### 依赖检查

运行部署脚本前，确保：

```cmd
# 检查 Docker 是否运行
docker --version

# 检查 Docker Desktop 状态
docker info
```

---

## 🔧 配置说明

### API 密钥配置

部署需要以下 API 密钥：

1. **主 API 密钥** (必需)
   - 用于所有 LLM 引擎
   - 支持 OpenAI 兼容 API

2. **Tavily API 密钥** (必需)
   - 用于网络搜索
   - 获取地址: https://tavily.com

3. **Bocha API 密钥** (必需)
   - 用于多模态搜索
   - 获取地址: https://bochaai.com

### 环境配置文件

配置保存在 `BettaFish-main\.env`

示例：
```env
# ====================== LLM 配置 ======================
INSIGHT_ENGINE_API_KEY=sk-xxx...
INSIGHT_ENGINE_BASE_URL=https://vibecodingapi.ai/v1
INSIGHT_ENGINE_MODEL_NAME=gpt-4o

# =================== 网络工具配置 ====================
TAVILY_API_KEY=tvl-xxx...
BOCHA_WEB_SEARCH_API_KEY=sk-xxx...

# ===================== 数据库配置 =====================
DB_HOST=db
DB_PORT=5432
DB_USER=bettafish
DB_PASSWORD=bettafish_secure_xxx
DB_NAME=bettafish
DB_DIALECT=postgresql
```

---

## 🐛 常见问题

### Q1: 镜像拉取失败，提示 403 Forbidden

**原因**: Docker 配置了无效的镜像源 `docker.1panel.live`

**解决方案**:
```cmd
# 方案 1: v4.0.3 自动绕过（推荐）
# 直接运行部署脚本即可

# 方案 2: 手动清理
fix-docker-mirrors.bat

# 方案 3: GUI 操作
# Docker Desktop → Settings → Docker Engine
# 删除 "registry-mirrors" 配置
# Apply & Restart
```

### Q2: API 密钥每次都要重新输入

**诊断步骤**:
```cmd
# 1. 运行诊断工具
debug-env.bat

# 2. 查看输出，确定问题类型

# 3. 可能的情况：
#    a) .env 文件不存在 → 部署在生成前失败
#    b) .env 存在但密钥为空 → 写入逻辑问题
#    c) .env 正常但读取失败 → 读取逻辑问题
```

### Q3: 容器启动失败

**检查步骤**:
```cmd
# 1. 查看容器状态
docker ps -a

# 2. 查看容器日志
docker logs bettafish-main-app-1

# 3. 检查端口占用
netstat -ano | findstr :5000

# 4. 重新部署
docker-compose down
docker-deploy-v4.bat
```

### Q4: 浏览器无法访问 localhost:5000

**排查步骤**:
```cmd
# 1. 检查容器是否运行
docker ps | findstr bettafish

# 2. 检查容器健康状态
docker inspect bettafish-main-app-1

# 3. 尝试直接访问
curl http://localhost:5000

# 4. 检查防火墙设置
```

更多问题请查看 [问题修复说明.md](问题修复说明.md)

---

## 🔄 版本更新历史

### v4.0.3 (2025-11-15) - 当前版本 ⭐

**核心改进**:
- ✅ 集成 quick-fix 成功逻辑
- ✅ 自动使用 DaoCloud/NJU 镜像加速源
- ✅ 删除临时镜像，只保留标准名称
- ✅ 显示拉取进度，提升用户体验
- ✅ 创建 debug-env.bat 诊断工具

**修复问题**:
- ✅ PostgreSQL 镜像拉取 403 错误
- ✅ 镜像列表中出现多个重复名称
- ✅ 拉取过程无进度提示

**详细说明**: [v4.0.3-更新说明.md](v4.0.3-更新说明.md)

### v4.0.2 (2025-11-15)

**改进**:
- ✅ 添加镜像源回退逻辑
- ⚠️ 隐藏了拉取进度（体验不佳）
- ❌ 没有删除临时镜像

### v4.0.1 (2025-11-15)

**初始版本**:
- ❌ 直接拉取官方源
- ❌ 被 docker.1panel.live 拦截

---

## 📖 技术文档

### 架构说明

```
BettaFish 系统架构

┌─────────────────────────────────────────────┐
│         Docker 容器化部署                    │
├─────────────────────────────────────────────┤
│                                              │
│  ┌──────────────┐      ┌─────────────────┐ │
│  │  BettaFish   │ ───▶ │   PostgreSQL    │ │
│  │  应用容器     │      │   数据库容器     │ │
│  │  (Port 5000) │      │   (Port 5432)   │ │
│  └──────────────┘      └─────────────────┘ │
│         │                                    │
│         ▼                                    │
│  ┌──────────────────────────────────────┐  │
│  │  LLM 引擎 (7个独立引擎)              │  │
│  │  - Insight Engine (洞察)            │  │
│  │  - Media Engine (媒体)              │  │
│  │  - Query Engine (查询)              │  │
│  │  - Report Engine (报告)             │  │
│  │  - MindSpider (爬虫)                │  │
│  │  - Forum Host (论坛)                │  │
│  │  - Keyword Optimizer (关键词)       │  │
│  └──────────────────────────────────────┘  │
│         │                                    │
│         ▼                                    │
│  ┌──────────────────────────────────────┐  │
│  │  外部服务集成                         │  │
│  │  - Tavily Search (网络搜索)         │  │
│  │  - Bocha AI (多模态搜索)            │  │
│  └──────────────────────────────────────┘  │
│                                              │
└─────────────────────────────────────────────┘
```

### 镜像拉取策略

```
PostgreSQL 镜像拉取流程

检查 postgres:15 是否存在
    │
    ├─ 已存在 ──▶ 跳过拉取 ──▶ 继续部署
    │
    └─ 不存在 ──▶ 开始拉取
                    │
                    ├─ 第一选择: DaoCloud
                    │  docker.m.daocloud.io/postgres:15
                    │  │
                    │  ├─ 成功 ──▶ 标记 + 删除临时 ──▶ 完成 ✅
                    │  └─ 失败 ──▶ 尝试下一个
                    │
                    ├─ 第二选择: 南京大学
                    │  docker.nju.edu.cn/postgres:15
                    │  │
                    │  ├─ 成功 ──▶ 标记 + 删除临时 ──▶ 完成 ✅
                    │  └─ 失败 ──▶ 尝试下一个
                    │
                    └─ 第三选择: 官方源
                       postgres:15
                       │
                       ├─ 成功 ──▶ 完成 ✅
                       └─ 失败 ──▶ 报错并退出 ❌
```

---

## 🤝 贡献指南

### 反馈问题

如遇到问题，请提供：

1. **系统信息**
   ```cmd
   systeminfo | findstr /B /C:"OS Name" /C:"OS Version"
   docker --version
   docker info
   ```

2. **诊断输出**
   ```cmd
   debug-env.bat > debug-output.txt
   diagnose.bat > diagnose-output.txt
   ```

3. **错误截图**
   - 错误信息截图
   - Docker Desktop 设置截图

### 改进建议

欢迎提交改进建议：
- 功能优化
- 用户体验改进
- 文档完善
- Bug 修复

---

## 📜 许可证

本项目遵循 BettaFish 官方项目的许可证。

详见: https://github.com/666ghj/BettaFish

---

## 🔗 相关链接

- **BettaFish 官方仓库**: https://github.com/666ghj/BettaFish
- **Docker Desktop 下载**: https://www.docker.com/products/docker-desktop
- **Tavily API**: https://tavily.com
- **Bocha AI**: https://bochaai.com

---

## 📞 技术支持

### 文档资源

- [使用指南](使用指南-v4.0.3.txt) - 完整使用说明
- [快速修复指南](快速修复指南.txt) - 快速参考
- [问题修复说明](问题修复说明.md) - 故障排查
- [更新说明](v4.0.3-更新说明.md) - 技术详情

### 诊断工具

```cmd
debug-env.bat       # API 密钥诊断
diagnose.bat        # 系统全面诊断
fix-docker-mirrors.bat  # 镜像源修复
fix-all.bat         # 编码修复
```

---

## ✅ 快速检查清单

部署前检查：

- [ ] Docker Desktop 已安装并运行
- [ ] Windows 版本支持（Win10/11 64-bit）
- [ ] 磁盘空间充足（20GB+）
- [ ] 已准备好 API 密钥

部署后验证：

- [ ] 容器运行正常 (`docker ps`)
- [ ] 浏览器能访问 localhost:5000
- [ ] API 密钥配置正确
- [ ] 数据库连接正常

---

## 🎉 开始使用

```cmd
# 立即开始部署
docker-deploy-v4.bat
```

**享受流畅的一键部署体验！** 🚀

---

<div align="center">

**BettaFish Windows 部署工具 v4.0.3**

由 Claude Code 精心打造 | 2025-11-15

</div>
