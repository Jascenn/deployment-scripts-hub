# Deployment Scripts Hub

> 🚀 部署工具集合仓库 - 收集各类项目的跨平台自动化部署工具

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Maintained](https://img.shields.io/badge/Maintained-Yes-green.svg)](https://github.com/Jascenn/deployment-scripts-hub)

---

## 📖 简介

这是一个专门用于存储和分享各类项目部署工具的仓库。每个项目都有独立的目录，包含完整的跨平台部署工具和中文文档。

### 仓库特点

- ✅ **跨平台支持** - Windows、macOS、Linux 完整支持
- ✅ **一键部署** - 简单易用的自动化部署脚本
- ✅ **智能修复** - 自动检测和修复常见问题
- ✅ **交互式菜单** - 图形化操作界面
- ✅ **中文文档** - 完整的中文使用文档
- ✅ **持续更新** - 随项目更新及时维护

---

## 🗂️ 项目列表

### 1. BettaFish - AI 助手部署工具包

BettaFish 是由 [LIONCC.AI](https://lioncc.ai) 开发的 AI 助手系统。本仓库提供完整的跨平台部署工具包。

#### 📂 项目目录

```
bettafish/
├── Linux_macOS/          # macOS 和 Linux 部署工具
└── Windows/              # Windows 部署工具
```

#### 🐧 Linux / macOS 部署

**特色功能**：
- 🎯 交互式菜单系统
- 🚀 一键自动部署
- 🔍 系统诊断工具
- 🧹 Docker 清理工具
- 📋 路径验证工具

**使用方式**：

```bash
# 方法 1: 克隆仓库
git clone https://github.com/Jascenn/deployment-scripts-hub.git
cd deployment-scripts-hub/bettafish/Linux_macOS

# 启动菜单（推荐）
./menu.sh

# 或直接部署
./docker-deploy.sh
```

**文档**: [bettafish/Linux_macOS/README.md](bettafish/Linux_macOS/README.md)

#### 🪟 Windows 部署

**特色功能**：
- 🖱️ 双击运行，无需命令行
- 🎨 彩色 PowerShell 界面
- 🛠️ 智能修复工具 (fix-all)
- 📋 交互式菜单系统
- 📖 HTML 可视化指南
- 🗂️ Plan C 结构（scripts/ 子目录）

**使用方式**：

```powershell
# 1. 克隆或下载仓库
git clone https://github.com/Jascenn/deployment-scripts-hub.git

# 2. 进入 Windows 目录
cd deployment-scripts-hub\bettafish\Windows

# 3. 双击运行
menu.bat           # 交互式菜单（推荐）
deploy.bat         # 快速部署
fix-all.bat        # 智能修复
```

**文档**: [bettafish/Windows/README.md](bettafish/Windows/README.md)

#### 📊 BettaFish 版本信息

| 平台 | 版本 | 部署时间 | 工具数量 | 文档数量 |
|------|------|---------|---------|---------|
| **Linux/macOS** | v2.1.0 | 5-10 分钟 | 6 个脚本 | 5 个文档 |
| **Windows** | v2.1.0 | 5-10 分钟 | 10 个脚本 | 7 个文档 |

#### 🎯 核心功能

- **AI 模型集成**: 支持 VibeCoding API、OpenAI、Claude、Gemini
- **网络搜索**: 可选集成 Tavily API、Bocha API
- **Docker 部署**: 基于 Docker Compose 的容器化部署
- **镜像加速**: 支持国内镜像源加速
- **智能诊断**: 自动检测环境问题并修复

---

## 📂 仓库结构

```
deployment-scripts-hub/
│
├── README.md                          # 本文件
├── QUICK_REFERENCE.md                 # 快速参考卡片
├── LICENSE                            # MIT 许可证
│
└── bettafish/                         # BettaFish 部署工具包
    │
    ├── Linux_macOS/                   # Linux 和 macOS 工具
    │   ├── README.md                  # 使用说明
    │   ├── START.txt                  # 快速开始
    │   ├── menu.sh                    # 交互式菜单 ⭐
    │   ├── docker-deploy.sh           # 一键部署 ⭐
    │   ├── diagnose.sh                # 系统诊断
    │   ├── docker-cleanup.sh          # Docker 清理
    │   ├── validate-paths.sh          # 路径验证
    │   ├── log-cleanup.sh             # 日志清理
    │   ├── docs/                      # 文档目录
    │   ├── backups/                   # 备份目录
    │   └── offline-packages/          # 离线包目录
    │
    └── Windows/                       # Windows 工具
        ├── README.md                  # 使用说明
        ├── README.txt                 # 文本说明
        ├── _START_HERE.txt            # 新手指南 ⭐
        ├── START.md                   # Markdown 指南
        ├── menu.bat                   # 交互式菜单 ⭐
        ├── deploy.bat                 # 快速部署 ⭐
        ├── fix-all.bat                # 智能修复 ⭐
        ├── docker-deploy.bat          # 完整部署
        ├── diagnose.bat               # 系统诊断
        ├── scripts/                   # PowerShell 脚本目录
        │   ├── menu.ps1               # 菜单脚本
        │   ├── docker-deploy.ps1      # 部署脚本
        │   ├── fix-all.ps1            # 修复脚本
        │   ├── diagnose.ps1           # 诊断脚本
        │   ├── download-project.ps1   # 下载脚本
        │   └── fix-docker-mirrors.ps1 # 镜像源修复
        ├── docs/                      # 文档目录
        ├── backups/                   # 备份目录
        ├── offline-packages/          # 离线包目录
```

---

## 🚀 快速开始

### Linux / macOS 用户

```bash
# 1. 克隆仓库
git clone https://github.com/Jascenn/deployment-scripts-hub.git

# 2. 进入目录
cd deployment-scripts-hub/bettafish/Linux_macOS

# 3. 启动菜单（推荐）
./menu.sh

# 或直接部署
./docker-deploy.sh
```

### Windows 用户

```powershell
# 方法 1: 使用交互式菜单（最推荐）
# 1. 下载或克隆仓库
# 2. 进入 deployment-scripts-hub\bettafish\Windows
# 3. 双击 menu.bat

# 方法 2: 快速部署
# 双击 deploy.bat

# 方法 3: 遇到问题？使用智能修复
# 双击 fix-all.bat
```

---

## 📝 系统要求

### 通用要求

- **Docker**: Docker Desktop 20.10+ (Windows/macOS) 或 Docker Engine 20.10+ (Linux)
- **磁盘空间**: 至少 20GB 可用空间
- **内存**: 建议 8GB 或以上
- **网络**: 稳定的互联网连接

### API 密钥准备

**必需的 API 密钥**（至少选择一个）:
- VibeCoding API（推荐）- [https://vibecodingapi.ai](https://vibecodingapi.ai)
- OpenAI API
- Claude API
- Gemini API
- 其他兼容 OpenAI 格式的服务

**可选的 API 密钥**（增强搜索功能）:
- Tavily API - [https://tavily.com](https://tavily.com)
- Bocha API - [https://bocha.ai](https://bocha.ai)

---

## 🛠️ 添加新项目

欢迎贡献新的部署工具到这个仓库！

### 步骤

1. **Fork 本仓库**
   ```bash
   # 在 GitHub 上点击 Fork
   git clone https://github.com/YOUR_USERNAME/deployment-scripts-hub.git
   ```

2. **创建项目目录**
   ```bash
   cd deployment-scripts-hub
   mkdir -p newproject/{Linux_macOS,Windows}
   ```

3. **添加部署脚本**
   - 参考 `bettafish/` 的结构
   - 为 Linux/macOS 和 Windows 分别创建工具

4. **创建文档**
   - README.md - 项目说明
   - 使用指南
   - 常见问题解答

5. **提交 Pull Request**
   ```bash
   git add newproject/
   git commit -m "Add newproject deployment toolkit"
   git push origin main
   ```

---

## 🤝 贡献指南

### 代码规范

- ✅ 脚本必须支持 `--help` 参数
- ✅ 必须包含详细的错误处理
- ✅ 必须有完整的中文文档
- ✅ Windows 脚本必须支持双击运行
- ✅ Shell 脚本通过 shellcheck 检查

### 文档规范

- ✅ README.md 必须包含使用说明
- ✅ 必须提供快速开始指南
- ✅ 必须包含常见问题解答
- ✅ 建议提供截图或演示

### 提交规范

```
<type>(<scope>): <subject>

类型 (type):
- feat: 新功能
- fix: 修复
- docs: 文档
- refactor: 重构
- test: 测试

范围 (scope): 项目名称或 all

示例:
feat(bettafish): Add intelligent fix-all tool for Windows
fix(bettafish): Fix encoding issues in PowerShell scripts
docs(all): Update README with new structure
```

---

## 📊 项目统计

| 项目 | 平台 | 版本 | 脚本数 | 文档数 | 成功率 |
|------|------|------|-------|-------|--------|
| BettaFish | Linux/macOS | v2.1.0 | 6 | 5 | 95% |
| BettaFish | Windows | v2.1.0 | 10 | 7 | 98% |

---

## ❓ 常见问题

### Q1: 这个仓库是做什么的？

**A**: 这是一个部署工具集合仓库，专门收集各类项目的跨平台自动化部署工具。目前包含 BettaFish AI 助手的完整部署工具包，未来会添加更多项目。

### Q2: 所有工具都支持哪些平台？

**A**: 目前所有工具都支持：
- ✅ Windows (原生 BAT/PowerShell)
- ✅ macOS (Intel & Apple Silicon)
- ✅ Linux (Ubuntu, Debian, CentOS 等主流发行版)

### Q3: 需要什么技术背景？

**A**: 不需要！所有工具都设计为用户友好：
- Windows: 双击 .bat 文件即可
- macOS/Linux: 运行 .sh 脚本
- 提供交互式菜单和详细提示

### Q4: 如何更新已部署的项目？

**A**: 每个项目的 README 中都有更新说明。通常步骤：
```bash
# 拉取最新代码
cd deployment-scripts-hub
git pull

# 重新运行部署脚本
cd bettafish/Linux_macOS
./docker-deploy.sh
```

### Q5: 遇到问题怎么办？

**A**:
1. 查看项目的 README 和文档
2. Windows 用户可以运行 `fix-all.bat` 自动修复
3. 搜索 [Issues](https://github.com/Jascenn/deployment-scripts-hub/issues)
4. 创建新 Issue 寻求帮助

---

## 📜 许可证

本仓库采用 [MIT License](LICENSE) 许可证。

各子项目可能有不同的许可证，请查看具体项目目录。

---

## 🔗 相关链接

### 官方资源

- **GitHub 仓库**: https://github.com/Jascenn/deployment-scripts-hub
- **问题反馈**: https://github.com/Jascenn/deployment-scripts-hub/issues
- **Pull Requests**: https://github.com/Jascenn/deployment-scripts-hub/pulls

### BettaFish 相关

- **BettaFish 项目**: https://github.com/666ghj/BettaFish
- **VibeCoding API**: https://vibecodingapi.ai
- **LIONCC.AI**: https://lioncc.ai

### 博客文章

- **CodeCodex 博客**: https://codecodex.ai
- **BettaFish 一键部署指南**: https://codecodex.ai/2025-11-16/bettafish-cross-platform-deployment-toolkit.html

---

## 🎯 Roadmap

### 当前版本 v1.0

- ✅ BettaFish 跨平台部署工具包
- ✅ Windows 智能修复系统
- ✅ 交互式菜单系统
- ✅ 完整中文文档

### 计划中 v1.1

- ⏳ 添加更多项目部署工具
- ⏳ 创建 Release 版本
- ⏳ 添加 Gitee 镜像（国内加速）
- ⏳ Web 文档页面

### 远期计划 v2.0

- ⏳ CLI 工具开发
- ⏳ 可视化部署监控
- ⏳ 多语言支持（English）
- ⏳ 社区贡献模板

---

## 📞 联系方式

- **维护者**: LingYi（凌一）
- **博客**: https://lingyi.bio
- **GitHub**: [@Jascenn](https://github.com/Jascenn)
- **邮箱**: darkerrouge@gmail.com

### 技术支持

通过 CodeCodex 技术社群可获得：
- ✅ 部署工具包技术支持
- ✅ VibeCoding API 优惠
- ✅ 部署问题排查帮助
- ✅ 配置优化建议

---

## ⭐ Star History

如果这个仓库对您有帮助，请给一个 Star ⭐

[![Star History Chart](https://api.star-history.com/svg?repos=Jascenn/deployment-scripts-hub&type=Date)](https://star-history.com/#Jascenn/deployment-scripts-hub&Date)

---

**最后更新**: 2025-11-16
**仓库版本**: v1.0
**维护状态**: ✅ 积极维护中

---

**祝您使用愉快！** 🚀
