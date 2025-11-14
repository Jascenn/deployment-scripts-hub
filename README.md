# Deployment Scripts Hub

> 🚀 一站式部署脚本仓库 - 收集各种项目的自动化部署脚本

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Maintained](https://img.shields.io/badge/Maintained-Yes-green.svg)](https://github.com/Jascenn/deployment-scripts-hub)

---

## 📖 简介

这是一个专门用于存储和分享各种项目部署脚本的仓库。每个项目都有独立的目录，包含完整的部署工具和文档。

### 特点

- ✅ **一键部署** - 所有脚本支持 curl 直接执行
- ✅ **智能检测** - 自动检测网络环境和系统配置
- ✅ **代理支持** - 支持各种代理配置
- ✅ **详细文档** - 每个项目都有完整的使用说明
- ✅ **持续更新** - 随项目更新及时维护

---

## 🗂️ 项目列表

### 1. BettaFish (AI 对话系统)

**一键部署**：
```bash
curl -fsSL https://raw.githubusercontent.com/Jascenn/deployment-scripts-hub/main/bettafish/smart-deploy.sh | bash
```

**项目说明**：BettaFish 是一个基于 Docker 的 AI 对话系统

**文档**：[bettafish/README.md](bettafish/README.md)

**版本**：v2.1 | **部署时间**：5-8 分钟 | **镜像大小**：~2GB

---

## 📂 目录结构

```
deployment-scripts-hub/
│
├── README.md                          # 本文件
├── LICENSE                            # MIT 许可证
│
├── bettafish/                         # BettaFish 部署工具
│   ├── README.md                      # 项目说明
│   ├── smart-deploy.sh                # 智能部署脚本
│   ├── create-package.sh              # 打包脚本
│   ├── packages/                      # 部署包（通过 Release 分发）
│   └── docs/                          # 详细文档
│       ├── quick-start.md             # 快速开始
│       ├── advanced-config.md         # 高级配置
│       └── troubleshooting.md         # 问题排查
│
├── project-template/                  # 项目模板
│   ├── README.md                      # 模板说明
│   ├── smart-deploy.sh.template       # 部署脚本模板
│   └── docs/                          # 文档模板
│
└── scripts/                           # 通用工具脚本
    ├── check-docker.sh                # Docker 检查
    ├── check-network.sh               # 网络检查
    └── proxy-config.sh                # 代理配置
```

---

## 🚀 快速开始

### 方式 1: 使用特定项目的部署脚本

```bash
# 查看项目列表（上方）
# 复制对应的一键部署命令
curl -fsSL https://raw.githubusercontent.com/Jascenn/deployment-scripts-hub/main/PROJECT_NAME/smart-deploy.sh | bash
```

### 方式 2: 从 Release 下载

```bash
# 下载完整部署包
curl -fsSL https://github.com/Jascenn/deployment-scripts-hub/releases/download/bettafish-v2.1/BettaFish-Deployment-Kit.tar.gz -o bettafish.tar.gz

# 解压并部署
tar -xzf bettafish.tar.gz
cd BettaFish-Deployment-Kit
./smart-deploy.sh
```

### 方式 3: Clone 整个仓库

```bash
git clone https://github.com/Jascenn/deployment-scripts-hub.git
cd deployment-scripts-hub/bettafish
./smart-deploy.sh
```

---

## 📝 使用参数

所有部署脚本都支持通用参数：

```bash
curl -fsSL https://raw.githubusercontent.com/Jascenn/deployment-scripts-hub/main/PROJECT/smart-deploy.sh | bash -s -- [选项]
```

### 通用参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `--proxy` | 设置代理 | `--proxy http://127.0.0.1:7890` |
| `--minimal` | 使用最小包 | `--minimal` |
| `--dir` | 指定目录 | `--dir ~/myproject` |
| `--skip-env-check` | 跳过环境检查 | `--skip-env-check` |
| `--help` | 显示帮助 | `--help` |

### 示例

```bash
# 使用代理部署
curl -fsSL https://raw.githubusercontent.com/Jascenn/deployment-scripts-hub/main/bettafish/smart-deploy.sh | bash -s -- --proxy http://127.0.0.1:7890

# 最小化部署到指定目录
curl -fsSL https://raw.githubusercontent.com/Jascenn/deployment-scripts-hub/main/bettafish/smart-deploy.sh | bash -s -- --minimal --dir ~/bettafish
```

---

## 🛠️ 添加新项目

### 步骤 1: 创建项目目录

```bash
cd deployment-scripts-hub
mkdir -p myproject/docs
```

### 步骤 2: 复制模板

```bash
cp project-template/smart-deploy.sh.template myproject/smart-deploy.sh
cp project-template/README.md myproject/README.md
```

### 步骤 3: 自定义脚本

编辑 `myproject/smart-deploy.sh`，修改：
- 项目名称
- 下载 URL
- 部署逻辑

### 步骤 4: 创建文档

在 `myproject/docs/` 下创建：
- `quick-start.md` - 快速开始
- `advanced-config.md` - 高级配置
- `troubleshooting.md` - 问题排查

### 步骤 5: 更新主 README

在本文件的"项目列表"中添加新项目信息。

### 步骤 6: 提交

```bash
git add myproject/
git commit -m "Add myproject deployment scripts"
git push
```

---

## 📦 Release 规范

### 命名规范

```
{project-name}-v{version}
```

**示例**：`bettafish-v2.1`

### 文件规范

每个 Release 应包含：

1. **完整部署包** - `{ProjectName}-Deployment-Kit.tar.gz`
2. **最小核心包** - `{ProjectName}-Minimal.tar.gz`
3. **部署脚本** - `smart-deploy.sh`
4. **SHA256 校验** - `*.sha256`
5. **变更日志** - Release Notes

### 创建 Release 示例

```bash
# 创建部署包
cd bettafish
./create-package.sh

# 创建 Release
gh release create bettafish-v2.1 \
    packages/BettaFish-Deployment-Kit.tar.gz \
    packages/BettaFish-Minimal.tar.gz \
    smart-deploy.sh \
    --title "BettaFish Deployment Kit v2.1" \
    --notes "$(cat CHANGELOG.md)"
```

---

## 🔐 安全建议

### 1. 验证脚本来源

始终从官方仓库下载：
```bash
https://github.com/Jascenn/deployment-scripts-hub
```

### 2. 先查看再执行

```bash
# 下载脚本
curl -fsSL https://raw.githubusercontent.com/Jascenn/deployment-scripts-hub/main/bettafish/smart-deploy.sh -o deploy.sh

# 查看内容
cat deploy.sh

# 确认安全后执行
bash deploy.sh
```

### 3. 使用 SHA256 校验

```bash
# 下载校验和
curl -fsSL https://github.com/Jascenn/deployment-scripts-hub/releases/download/bettafish-v2.1/BettaFish-Deployment-Kit.tar.gz.sha256

# 验证文件
sha256sum -c BettaFish-Deployment-Kit.tar.gz.sha256
```

### 4. 使用 HTTPS

所有 URL 都使用 HTTPS 协议。

---

## 🤝 贡献指南

欢迎贡献新的部署脚本或改进现有脚本！

### 贡献流程

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/new-project`)
3. 提交更改 (`git commit -m 'Add new project deployment'`)
4. 推送到分支 (`git push origin feature/new-project`)
5. 创建 Pull Request

### 代码规范

- ✅ 所有脚本必须支持 `--help` 参数
- ✅ 必须包含详细的错误处理
- ✅ 必须支持 `--proxy` 参数
- ✅ 必须有完整的 README 文档
- ✅ 必须通过 shellcheck 检查

### 提交规范

```
<type>(<scope>): <subject>

<type>: feat, fix, docs, style, refactor, test, chore
<scope>: 项目名称或 all
<subject>: 简短描述
```

**示例**：
```
feat(bettafish): Add proxy auto-detection
fix(bettafish): Fix network timeout issue
docs(all): Update README with new examples
```

---

## 📊 项目统计

| 项目 | 版本 | 脚本数 | 文档数 | 部署时间 | 成功率 |
|------|------|--------|--------|----------|--------|
| BettaFish | v2.1 | 3 | 6 | 5-8分钟 | 95% |
| _(待添加)_ | - | - | - | - | - |

---

## 🌐 国内访问

### Gitee 镜像（自动同步）

```bash
# 使用 Gitee 镜像
curl -fsSL https://gitee.com/Jascenn/deployment-scripts-hub/raw/main/bettafish/smart-deploy.sh | bash
```

所有脚本会自动检测网络环境，优先使用国内镜像源。

---

## ❓ 常见问题

### Q1: 所有项目都支持一键部署吗？

**A**: 是的，仓库中的所有项目都支持 curl 一键部署。

### Q2: 如何更新已部署的项目？

**A**: 每个项目的 README 中都有更新说明，通常是：
```bash
cd project-directory
docker-compose pull
docker-compose up -d
```

### Q3: 脚本支持哪些操作系统？

**A**:
- ✅ macOS (Intel & Apple Silicon)
- ✅ Linux (Ubuntu, Debian, CentOS, etc.)
- ✅ Windows (WSL2)

### Q4: 需要什么前置条件？

**A**: 大多数项目需要：
- Docker Desktop (或 Docker Engine + Docker Compose)
- 稳定的网络连接
- 足够的磁盘空间（具体见项目说明）

### Q5: 遇到问题怎么办？

**A**:
1. 查看项目的 `docs/troubleshooting.md`
2. 搜索 [Issues](https://github.com/Jascenn/deployment-scripts-hub/issues)
3. 创建新 Issue

---

## 📜 许可证

本仓库采用 [MIT License](LICENSE) 许可证。

各子项目可能有不同的许可证，请查看具体项目目录。

---

## 🔗 相关链接

- **官方仓库**: https://github.com/Jascenn/deployment-scripts-hub
- **问题反馈**: https://github.com/Jascenn/deployment-scripts-hub/issues
- **讨论区**: https://github.com/Jascenn/deployment-scripts-hub/discussions
- **Wiki**: https://github.com/Jascenn/deployment-scripts-hub/wiki

---

## 🎯 Roadmap

### v1.0 (当前)
- ✅ BettaFish 部署脚本
- ✅ 项目模板
- ✅ 通用工具脚本
- ✅ 完整文档

### v1.1 (计划中)
- ⏳ 添加更多项目
- ⏳ Web 界面（脚本选择器）
- ⏳ 自动化测试 CI/CD
- ⏳ Docker 镜像加速器配置

### v2.0 (远期)
- ⏳ 支持 Kubernetes 部署
- ⏳ 可视化部署监控
- ⏳ 多语言支持

---

## 📞 联系方式

- **维护者**: Your Name
- **邮箱**: your.email@example.com
- **博客**: https://your-blog.com

---

## ⭐ Star History

如果这个仓库对您有帮助，请给一个 Star ⭐

[![Star History Chart](https://api.star-history.com/svg?repos=Jascenn/deployment-scripts-hub&type=Date)](https://star-history.com/#Jascenn/deployment-scripts-hub&Date)

---

**最后更新**: 2025-01-14
**仓库版本**: v1.0
**维护状态**: ✅ 积极维护中
