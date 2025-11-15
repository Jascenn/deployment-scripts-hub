# BettaFish Windows 部署工具

> 一键部署 BettaFish 舆情分析系统

**版本**: 最新版
**状态**: ✅ 稳定可用
**平台**: Windows 10/11

---

## 🚀 快速开始

### 一键部署（推荐）

```cmd
1. 确保 Docker Desktop 正在运行
2. 双击运行: docker-deploy.bat
3. 按提示输入 API 密钥
```

部署完成后自动打开浏览器: http://localhost:5000

---

## 🛠️ 核心工具

### 主要工具

| 文件 | 功能 | 使用场景 |
|------|------|----------|
| **docker-deploy.bat** | 一键完整部署 | ⭐ 首选工具 |
| **download-project.bat** | 下载项目源码 | 单独下载项目 |
| **quick-fix.bat** | 预拉取 Docker 镜像 | 提前准备镜像 |

### 诊断工具

| 文件 | 功能 | 使用时机 |
|------|------|----------|
| **debug-env.bat** | API 密钥诊断 | 密钥不持久化时 |
| **diagnose.bat** | 系统全面诊断 | 遇到问题时 |

### 修复工具

| 文件 | 功能 | 使用时机 |
|------|------|----------|
| **fix-docker-mirrors.bat** | 清理镜像源配置 | 遇到 403 错误 |
| **fix-all.bat** | 修复编码问题 | 脚本报错时 |

---

## 📚 使用文档

| 文档 | 内容 | 适用场景 |
|------|------|----------|
| [使用指南](使用指南-最新版.txt) | 完整使用说明 | 详细了解所有功能 |
| [快速修复指南](快速修复指南.txt) | 常见问题快速参考 | 快速查找解决方案 |
| [问题修复说明](问题修复说明.md) | 详细故障排查 | 深入诊断问题 |

---

## ✨ 最新版 核心特性

### 自动镜像加速

- ✅ 自动使用国内镜像源（DaoCloud / NJU）
- ✅ 绕过 `docker.1panel.live` 403 错误
- ✅ 三级回退：DaoCloud → NJU → 官方源
- ✅ 无需手动配置 Docker

### 智能部署流程

```
检查 Docker → 下载项目 → 配置密钥 → 拉取镜像 → 启动容器 → 打开浏览器
```

---

## 🐛 常见问题

### Q: 镜像拉取失败，提示 403 Forbidden

**答**: 最新版 已自动解决此问题。如仍失败：

```cmd
fix-docker-mirrors.bat
```

或手动清理 Docker Desktop 设置中的镜像源配置。

### Q: API 密钥每次都要重新输入

**答**: 运行诊断工具：

```cmd
debug-env.bat
```

根据输出结果确定问题原因。

### Q: 容器启动失败

**答**: 检查容器状态：

```cmd
docker ps -a
docker logs bettafish-main-app-1
```

然后重新部署：

```cmd
cd BettaFish-main
docker-compose down
cd ..
docker-deploy.bat
```

---

## 📋 部署要求

- **系统**: Windows 10/11 (64-bit)
- **Docker Desktop**: 最新版本（需运行中）
- **内存**: 建议 8GB+
- **磁盘**: 至少 20GB 可用空间

### API 密钥准备

需要以下 API 密钥：

1. **主 API 密钥** (必需) - OpenAI 兼容 API
2. **Tavily API 密钥** (必需) - 网络搜索 - https://tavily.com
3. **Bocha API 密钥** (必需) - 多模态搜索 - https://bochaai.com

---

## 📂 目录结构

```
Windows-Version/
├── docker-deploy.bat          ← 主部署脚本
├── download-project.bat          ← 下载项目
├── quick-fix.bat                 ← 预拉取镜像
├── debug-env.bat                 ← 密钥诊断
├── diagnose.bat                  ← 系统诊断
├── fix-docker-mirrors.bat        ← 镜像源修复
├── fix-all.bat                   ← 编码修复
│
├── README.md                     ← 本文件
├── 使用指南-最新版.txt          ← 详细使用说明
├── 快速修复指南.txt             ← 快速参考
├── 问题修复说明.md              ← 故障排查指南
│
├── BettaFish-main/              ← 项目源码（自动下载）
│   ├── .env                     ← 环境配置（自动生成）
│   ├── docker-compose.yml       ← Docker 编排
│   └── ...
│
└── docs-archive/                ← 历史文档归档
```

---

## 🔧 技术细节

### 镜像拉取策略

最新版 使用智能三级回退策略：

```
1. DaoCloud 镜像源 (docker.m.daocloud.io)
   ↓ 失败
2. 南京大学镜像源 (docker.nju.edu.cn)
   ↓ 失败
3. 官方源 (docker.io)
   ↓ 失败
报错并提供修复指导
```

### 为什么不会遇到 403 错误？

脚本明确指定镜像源地址，Docker 不会路由到 `registry-mirrors` 配置：

```powershell
# 绕过 Docker 镜像源配置
docker pull docker.m.daocloud.io/postgres:15
docker tag docker.m.daocloud.io/postgres:15 postgres:15
docker rmi docker.m.daocloud.io/postgres:15  # 删除临时镜像
```

---

## 🎯 验证部署

部署成功后验证：

```cmd
# 1. 检查容器运行
docker ps

# 应看到:
# bettafish-main-app-1    (Port 5000)
# bettafish-main-db-1     (Port 5432)

# 2. 检查镜像
docker images

# 应看到:
# postgres                         15
# ghcr.io/666ghj/bettafish         latest

# 3. 访问应用
# 浏览器打开: http://localhost:5000
```

---

## 🔗 相关链接

- **BettaFish 官方**: https://github.com/666ghj/BettaFish
- **Docker Desktop**: https://www.docker.com/products/docker-desktop
- **Tavily API**: https://tavily.com
- **Bocha AI**: https://bochaai.com

---

## 📞 获取帮助

### 查看文档

```
使用指南-最新版.txt       - 完整使用说明
快速修复指南.txt          - 快速参考
问题修复说明.md           - 故障排查
```

### 运行诊断

```cmd
debug-env.bat            - API 密钥诊断
diagnose.bat             - 系统诊断
```

### 历史文档

更多技术文档在 `docs-archive/` 目录

---

## ✅ 快速检查清单

**部署前**:
- [ ] Docker Desktop 已安装并运行
- [ ] 已准备好 3 个 API 密钥
- [ ] 磁盘空间充足 (20GB+)

**部署后**:
- [ ] 容器运行正常 (`docker ps`)
- [ ] 能访问 http://localhost:5000
- [ ] 密钥配置保存在 `.env`

---

<div align="center">

**立即开始部署**

```cmd
docker-deploy.bat
```

🎉 享受流畅的一键部署体验！

---

**BettaFish Windows 部署工具 最新版**
精心打造 | 2025-11-15

</div>
