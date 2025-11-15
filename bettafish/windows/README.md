# BettaFish Windows 部署工具包

> Windows 系统专用的一键部署工具包，支持 BAT 和 PowerShell 双脚本模式

**项目作者**: [LIONCC.AI](https://lioncc.ai)
**官方 API**: [VibeCoding API](https://vibecodingapi.ai)
**GitHub**: [BettaFish](https://github.com/666ghj/BettaFish)

---

## 📖 快速开始

### 🎯 首次使用（推荐新手）

1. **阅读快速指南**
   ```
   双击打开：START.txt
   ```

2. **运行部署脚本**
   ```
   双击：docker-deploy.bat
   ```

3. **按提示输入 API 密钥**
   - VibeCoding API: https://vibecodingapi.ai

### 💡 两种使用方式

#### 方式 A：BAT 脚本（简单）✨

**适合**：不熟悉 PowerShell 的用户

**优点**：
- ✅ 双击即可运行
- ✅ 无需配置权限
- ✅ 简单易用

**使用**：
```
双击 docker-deploy.bat
```

#### 方式 B：PowerShell 脚本（推荐）🚀

**适合**：需要完整功能的用户

**优点**：
- ✅ 功能强大
- ✅ 错误处理完善
- ✅ 日志详细

**使用**：
```
右键 docker-deploy.ps1 -> 使用 PowerShell 运行
```

**首次运行可能需要**：
```powershell
# 以管理员身份打开 PowerShell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## 📂 目录结构

```
Windows/
├── 📄 _START_HERE.txt             # ⭐ 从这里开始！
├── 📄 START.md                    # 快速开始说明
├── 📄 README.md                   # 本文档
│
├── 🎯 menu.bat                    # ⭐ 交互式菜单（主入口）
├── 🔧 fix-all.bat                 # 智能修复工具
├── 🚀 deploy.bat                  # 快速部署
│
├── 🚀 docker-deploy.bat           # 完整部署脚本
├── 🔍 diagnose.bat                # 系统诊断
├── 📥 download-project.bat        # 项目下载
├── 🛠️ fix-docker-mirrors.bat      # 镜像源修复
│
├── 📂 scripts/                    # PowerShell 实现脚本
│   ├── menu.ps1                   # 菜单实现
│   ├── fix-all.ps1                # 修复工具实现
│   ├── docker-deploy.ps1          # 部署实现
│   ├── diagnose.ps1               # 诊断实现
│   ├── download-project.ps1       # 下载实现
│   └── fix-docker-mirrors.ps1     # 镜像修复实现
│
├── 📂 docs/                       # 用户文档
│   ├── README.md                  # 文档索引
│   ├── 新手入门指南.html          # 图文教程
│   ├── 使用指南.html              # 快速参考
│   ├── 问题修复说明.md            # 故障排查
│   └── 快速修复指南.txt           # 常见问题
│
├── 📂 logs/                       # 部署日志（自动创建）
├── 📂 backups/                    # 配置备份（自动创建）
├── 📂 offline-packages/           # 离线安装包
└── 📂 BettaFish-main/             # BettaFish 源码（部署后生成）
```

---

## 🛠️ 可用工具

### 0. menu（交互式菜单）⭐ 推荐

**功能**：统一管理所有功能的交互式菜单

**使用**：
```bash
双击 menu.bat
```

**菜单选项**：
- 1) 部署/更新 BettaFish
- 2) 系统诊断
- 3) 下载 BettaFish 源码
- 4) 修复 Docker 镜像源
- 5-9) Docker 服务管理（启动/停止/重启/状态/日志）
- d) 打开用户文档
- h) 显示帮助信息
- 0) 退出

**优势**：
- 图形化界面，无需记忆命令
- 彩色输出，清晰直观
- 集成所有常用功能
- 新手友好

### 1. fix-all（智能修复工具）🔧 强力推荐

**功能**：自动检测并修复常见问题

**使用**：
```bash
# 完整检测
双击 fix-all.bat

# 仅修复编码问题（快速）
.\fix-all.ps1 -EncodingOnly

# 快速修复（编码 + Docker）
.\fix-all.ps1 -QuickFix
```

**自动修复**：
- ✅ 文件编码问题（UTF-8 BOM）
- ✅ Docker 服务未启动
- ✅ 端口占用冲突
- ✅ 项目文件缺失/损坏
- ✅ 配置文件错误
- ✅ Docker 镜像缺失
- ✅ 容器异常退出

**适用场景**：
- **首次使用遇到问题**
- **菜单或脚本显示乱码**（编码问题）
- **部署失败不知原因**
- **服务无法访问**
- **定期系统健康检查**

**特色功能**：
- 智能检测：自动识别问题类型
- 自动修复：一键解决常见问题
- 安全备份：修复前自动备份
- 详细报告：生成诊断报告

### 2. docker-deploy（部署脚本）

**功能**：一键部署 BettaFish

**使用**：
```bash
# BAT 方式
双击 docker-deploy.bat

# PowerShell 方式
右键 docker-deploy.ps1 -> 使用 PowerShell 运行
```

**流程**：
1. 检查 Docker 环境
2. 下载 BettaFish 源码（如果不存在）
3. 配置 API 密钥
4. 拉取 Docker 镜像
5. 启动服务

### 3. diagnose（系统诊断）

**功能**：检查系统状态和服务运行情况

**使用**：
```bash
双击 diagnose.bat 或 diagnose.ps1
```

**检查项**：
- Docker 安装状态
- 容器运行状态
- 端口监听情况
- 磁盘空间
- 服务日志

### 4. download-project（项目下载）

**功能**：单独下载 BettaFish 源码

**使用**：
```bash
双击 download-project.bat 或 download-project.ps1
```

**场景**：
- 预先下载源码
- 更新到最新版本
- 网络问题重新下载

### 5. fix-docker-mirrors（镜像修复）

**功能**：修复 Docker 镜像源配置

**使用**：
```bash
双击 fix-docker-mirrors.bat 或 fix-docker-mirrors.ps1
```

**适用**：
- 国内网络拉取镜像慢
- 配置镜像加速
- 镜像源连接失败

---

## ⚙️ 系统要求

| 项目 | 要求 | 说明 |
|------|------|------|
| **操作系统** | Windows 10+ / Windows Server 2016+ | 支持 64 位系统 |
| **Docker Desktop** | 最新版本 | 从 docker.com 下载 |
| **PowerShell** | 5.1+ | Windows 10+ 自带 |
| **磁盘空间** | 至少 20GB | 包含镜像和数据 |
| **内存** | 建议 8GB+ | 4GB 可运行 |

---

## 🔧 常见问题

### Q1: BAT 和 PowerShell 有什么区别？

**BAT 脚本**：
- 启动器，调用 PowerShell 脚本
- 双击即可运行
- 适合新手

**PowerShell 脚本**：
- 包含所有实际功能
- 功能更强大
- 错误处理更完善

### Q2: PowerShell 脚本无法运行？

**错误信息**：
```
无法加载文件，因为在此系统上禁止运行脚本
```

**解决方法**：
```powershell
# 以管理员身份打开 PowerShell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Q3: Docker Desktop 未安装？

**下载地址**：
- 官方：https://www.docker.com/products/docker-desktop
- 国内：https://mirrors.tuna.tsinghua.edu.cn/docker-ce/

**安装后**：
1. 启动 Docker Desktop
2. 等待 Docker 引擎启动完成
3. 重新运行部署脚本

### Q4: 如何获取 API 密钥？

**VibeCoding API（推荐）**：
- 访问：https://vibecodingapi.ai
- 注册账号
- 创建 API Key
- 专为 BettaFish 优化

**其他兼容 API**：
- OpenAI 官方 API
- Claude API
- 其他 OpenAI 兼容服务

### Q5: 部署需要多长时间？

**首次部署**：8-10 分钟
- 下载源码：1-2 分钟
- 拉取镜像：5-8 分钟（取决于网络）
- 配置启动：1 分钟

**更新部署**：3-5 分钟

### Q6: 端口被占用怎么办？

**检查占用**：
```powershell
netstat -ano | findstr :5001
```

**解决方法**：
1. 关闭占用端口的程序
2. 或修改 BettaFish 的端口配置

### Q7: 如何完全卸载？

```powershell
# 1. 停止并删除容器
cd BettaFish-main
docker-compose down -v

# 2. 删除镜像
docker rmi ghcr.io/666ghj/bettafish:latest
docker rmi postgres:15-alpine

# 3. 删除工具包
cd ..
Remove-Item -Recurse -Force BettaFish-Deployment-Kit
```

---

## 📚 详细文档

### 用户指南

- **[新手入门指南.html](docs/新手入门指南.html)** - 完整图文教程（推荐新手）
- **[使用指南.html](docs/使用指南.html)** - 快速参考手册
- **[问题修复说明.md](docs/问题修复说明.md)** - 故障排查指南
- **[快速修复指南.txt](docs/快速修复指南.txt)** - 常见问题速查

### 如何打开

**HTML 文件**：
```
双击即可在浏览器中打开
```

**Markdown 文件**：
```
使用文本编辑器打开（记事本、VS Code 等）
```

---

## 🌟 脚本特性

### 智能路径识别

所有脚本使用智能路径检测，支持：
- ✅ 放在任意目录运行
- ✅ 移动后无需修改配置
- ✅ 自动查找相关文件

### 双脚本模式

**BAT + PowerShell 配对设计**：
- BAT 作为启动器，简化使用
- PowerShell 包含核心功能
- 互不干扰，各取所需

### 完善的错误处理

- 环境检查
- 详细日志
- 友好提示
- 自动修复建议

---

## 🆘 获取帮助

### 在线支持

- **GitHub Issues**: https://github.com/Jascenn/deployment-scripts-hub/issues
- **项目主页**: https://github.com/666ghj/BettaFish
- **官方 API**: https://vibecodingapi.ai

### 本地诊断

```bash
# 运行诊断工具
双击 diagnose.bat
```

### 查看日志

```
logs/ 目录下的日志文件
```

---

## 📝 更新日志

### v1.0.0 (2025-01-16)

**首次发布**
- ✅ BAT + PowerShell 双脚本支持
- ✅ 一键部署功能
- ✅ 系统诊断工具
- ✅ 镜像源修复工具
- ✅ 完整的用户文档

**目录结构优化**
- ✅ 扁平化布局
- ✅ 清晰的文件组织
- ✅ 智能路径识别

---

## 📄 许可证

本部署工具包采用 MIT 许可证。

BettaFish 项目遵循其原项目许可证。

---

**祝您使用愉快！** 🐟✨

需要帮助？查看 [docs/新手入门指南.html](docs/新手入门指南.html)
