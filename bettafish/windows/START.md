# 🪟 Windows 用户部署指南 - 从这里开始

> 欢迎使用 BettaFish 部署工具包！

**项目作者**: [LIONCC.AI](https://lioncc.ai)
**官方 API**: https://vibecodingapi.ai
**GitHub**: https://github.com/666ghj/BettaFish

---

## 第一步：选择运行方式

本工具包提供两种运行方式，脚本都在主目录下：

### 方式 A：BAT 脚本（简单）✨

📄 **文件**: `docker-deploy.bat`

**优点**：
- ✅ 双击即可运行，无需配置
- ✅ 自动调用 PowerShell 脚本

**缺点**：
- ❌ 功能由 PowerShell 提供

**适合**: 不熟悉 PowerShell 的新手用户

### 方式 B：PowerShell 脚本（推荐）🚀

📄 **文件**: `docker-deploy.ps1`

**优点**：
- ✅ 功能强大
- ✅ 错误处理完善
- ✅ 日志详细

**缺点**：
- ❌ 首次使用需要设置执行策略

**适合**: 需要完整功能的用户

> **说明**: BAT 文件是启动器，实际功能由 PowerShell 脚本提供

---

## 第二步：快速部署（3 步完成）

### 【推荐】方式 A：使用 BAT 脚本（最简单）

1. **双击**: `docker-deploy.bat`
2. **输入 API 密钥**: 从 https://vibecodingapi.ai 获取
3. **等待完成**: 约 8-10 分钟

### 方式 B：使用 PowerShell 脚本（功能完整）

1. **右键点击** `docker-deploy.ps1` -> "使用 PowerShell 运行"
2. **输入 API 密钥**
3. **等待完成**

#### 如遇到执行策略错误：

```powershell
# 以管理员身份打开 PowerShell，运行：
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 方式 C：使用交互式菜单（推荐）🎯

1. **双击**: `menu.bat`
2. **选择**: `1) 部署/更新 BettaFish`
3. **按提示操作**

---

## 第三步：查看用户指南

📁 **docs/** 文件夹包含详细的使用指南：

| 文档 | 说明 |
|------|------|
| 📖 **新手入门指南.html** | 完整的图文教程（推荐新手阅读）<br>双击即可在浏览器中打开 |
| 📖 **使用指南.html** | 快速参考指南<br>常用操作和命令 |
| 📖 **问题修复说明.md** | 常见问题解决方案<br>故障排查步骤 |
| 📖 **快速修复指南.txt** | 快速参考<br>常见问题速查表 |

---

## 目录结构说明（扁平化布局）

```
Windows/
│
├── START.md                    # 📍 您当前正在阅读的文件
├── README.md                   # 📄 完整的使用文档
│
├── menu.bat                    # 🎯 交互式菜单（BAT）
├── menu.ps1                    # 🎯 交互式菜单（PowerShell）
│
├── docker-deploy.bat           # 🚀 部署脚本（BAT 启动器）
├── docker-deploy.ps1           # 🚀 部署脚本（PowerShell 核心）
│
├── diagnose.bat                # 🔍 诊断工具（BAT）
├── diagnose.ps1                # 🔍 诊断工具（PowerShell）
│
├── download-project.bat        # 📥 项目下载（BAT）
├── download-project.ps1        # 📥 项目下载（PowerShell）
│
├── fix-docker-mirrors.bat      # 🔧 镜像修复（BAT）
├── fix-docker-mirrors.ps1      # 🔧 镜像修复（PowerShell）
│
├── docs/                       # 📁 用户文档
│   ├── README.md
│   ├── 新手入门指南.html
│   ├── 使用指南.html
│   ├── 问题修复说明.md
│   └── 快速修复指南.txt
│
├── BettaFish-main/             # 📁 项目源码（部署后自动生成）
├── backups/                    # 📁 配置备份（自动创建）
├── logs/                       # 📁 部署日志（自动创建）
└── offline-packages/           # 📁 离线安装包
```

---

## 可用工具说明

| 工具 | 说明 |
|------|------|
| 🎯 **menu** | 交互式菜单<br>双击 `menu.bat` 打开菜单界面 |
| 🚀 **docker-deploy** | 一键部署 BettaFish<br>双击 `docker-deploy.bat` 即可开始部署 |
| 🔍 **diagnose** | 系统诊断工具<br>检查 Docker 状态、容器运行情况、端口监听等 |
| 📥 **download-project** | 单独下载 BettaFish 源码<br>用于预先下载或更新源码 |
| 🔧 **fix-docker-mirrors** | 修复 Docker 镜像源<br>国内网络拉取镜像慢时使用 |

---

## 常见问题（快速解答）

### Q1: BAT 和 PowerShell 脚本有什么区别？

**答**: BAT 是启动器，实际调用 PowerShell 脚本执行。
- 推荐新手直接双击 BAT 文件，无需配置
- 高级用户可以直接运行 PowerShell 脚本

### Q2: 应该双击哪个文件开始部署？

**答**:
- **最简单**: 双击 `docker-deploy.bat`
- **推荐**: 双击 `menu.bat` 使用交互式菜单

### Q3: PowerShell 脚本无法运行怎么办？

**答**: 以管理员身份打开 PowerShell，运行：

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Q4: 如何获取 API 密钥？

**答**:
1. 访问 https://vibecodingapi.ai
2. 注册并创建 API Key
3. 这是 LIONCC.AI 官方推荐的 API 服务

### Q5: 部署需要多长时间？

**答**:
- **首次部署**: 约 8-10 分钟（取决于网络速度）
- **更新部署**: 约 3-5 分钟

### Q6: Docker Desktop 必须安装吗？

**答**: 是的，必须先安装 Docker Desktop
- 下载地址: https://www.docker.com/products/docker-desktop

### Q7: 遇到错误怎么办？

**答**:
1. 运行诊断工具: 双击 `diagnose.bat`
2. 查看文档: `docs/问题修复说明.md`
3. 查看日志: `logs/` 目录

### Q8: 脚本可以移动到其他目录吗？

**答**: 可以！所有脚本使用智能路径检测，支持任意移动。

---

## 系统要求

| 项目 | 要求 |
|------|------|
| ✅ **操作系统** | Windows 10+ / Windows Server 2016+ |
| ✅ **Docker Desktop** | 最新版本（必须） |
| ✅ **PowerShell** | 5.1+（Windows 10+ 自带） |
| ✅ **磁盘空间** | 至少 20GB |
| ✅ **内存** | 建议 8GB+（4GB 可运行） |

---

## 部署后访问

部署成功后，访问以下地址：

| 服务 | 地址 | 说明 |
|------|------|------|
| 🌐 **主服务** | http://localhost:5001 | 综合功能界面 |
| 🌐 **Insight Engine** | http://localhost:8501 | 深度分析引擎 |
| 🌐 **Media Engine** | http://localhost:8502 | 媒体处理引擎 |
| 🌐 **Query Engine** | http://localhost:8503 | 快速问答引擎 |

> ⏱️ **提示**: 首次访问请等待 30-60 秒，让服务完全启动

---

## 需要帮助？

### 📖 详细文档

- **推荐**: 双击打开 `docs/新手入门指南.html`
- **参考**: 查看 `README.md`

### 🔧 问题排查

- **诊断**: 双击 `diagnose.bat`
- **指南**: 查看 `docs/问题修复说明.md`
- **日志**: 查看 `logs/` 目录

### 💬 在线支持

- **GitHub Issues**: https://github.com/Jascenn/deployment-scripts-hub/issues
- **项目主页**: https://github.com/666ghj/BettaFish

---

## 🎉 准备好了吗？

### 选择您的方式开始：

#### 1️⃣ 使用交互式菜单（推荐）

```
👉 双击 menu.bat
```

#### 2️⃣ 直接部署

```
👉 双击 docker-deploy.bat
```

---

**祝您部署顺利！** 🚀

**BettaFish by LIONCC.AI**

---
