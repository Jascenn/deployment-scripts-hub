# 🎯 Quick Reference - Deployment Scripts Hub

> 快速参考卡片 - 常用命令和链接

---

## 📦 仓库信息

- **仓库性质**: 部署工具集合仓库（非专属项目）
- **GitHub**: https://github.com/Jascenn/deployment-scripts-hub
- **本地路径**: `/Users/jascen/Development/deployment-scripts-hub`
- **状态**: ✅ 已上线并持续维护

---

## 📂 项目结构

```
deployment-scripts-hub/
├── bettafish/              # BettaFish 部署工具包
│   ├── Linux_macOS/        # Linux 和 macOS 工具
│   └── Windows/            # Windows 工具
└── (未来可添加更多项目)
```

---

## 🚀 用户使用（分享给别人）

### BettaFish 部署

#### Linux / macOS 用户

```bash
# 克隆仓库
git clone https://github.com/Jascenn/deployment-scripts-hub.git
cd deployment-scripts-hub/bettafish/Linux_macOS

# 方法 1: 交互式菜单（推荐）
./menu.sh

# 方法 2: 直接部署
./docker-deploy.sh

# 查看帮助
./docker-deploy.sh --help
```

#### Windows 用户

```powershell
# 1. 下载或克隆仓库
git clone https://github.com/Jascenn/deployment-scripts-hub.git

# 2. 进入 Windows 目录
cd deployment-scripts-hub\bettafish\Windows

# 3. 双击运行（任选一个）
menu.bat           # 交互式菜单（推荐）
deploy.bat         # 快速部署
fix-all.bat        # 智能修复（出问题时）
```

---

## 🔧 维护者操作

### 更新部署工具

```bash
cd /Users/jascen/Development/deployment-scripts-hub

# 修改文件
# Linux/macOS 工具
cd bettafish/Linux_macOS
nano menu.sh
nano docker-deploy.sh

# Windows 工具
cd ../Windows
nano scripts/menu.ps1
nano scripts/docker-deploy.ps1

# 提交更改
cd ../..
git add bettafish/
git commit -m "Update: description of changes"
git push
```

### 查看项目状态

```bash
cd /Users/jascen/Development/deployment-scripts-hub

# 查看 Git 状态
git status
git log --oneline -10

# 查看目录结构
tree -L 3 bettafish/

# 查看最近修改
git diff HEAD~1
```

### 添加新项目

```bash
cd /Users/jascen/Development/deployment-scripts-hub

# 1. 创建项目目录
mkdir -p newproject/{Linux_macOS,Windows}

# 2. 复制参考结构
cp -r bettafish/Linux_macOS/* newproject/Linux_macOS/
cp -r bettafish/Windows/* newproject/Windows/

# 3. 修改脚本和文档
cd newproject
# 编辑各个文件...

# 4. 更新主 README
cd ..
nano README.md
# 在项目列表中添加新项目

# 5. 提交
git add newproject/
git add README.md
git commit -m "Add newproject deployment toolkit"
git push
```

---

## 📂 重要文件位置

### BettaFish Linux/macOS

| 文件 | 用途 | 路径 |
|------|------|------|
| **menu.sh** | 交互式菜单 | `bettafish/Linux_macOS/menu.sh` |
| **docker-deploy.sh** | 一键部署脚本 | `bettafish/Linux_macOS/docker-deploy.sh` |
| **diagnose.sh** | 系统诊断 | `bettafish/Linux_macOS/diagnose.sh` |
| **docker-cleanup.sh** | Docker 清理 | `bettafish/Linux_macOS/docker-cleanup.sh` |
| **README.md** | 使用说明 | `bettafish/Linux_macOS/README.md` |

### BettaFish Windows

| 文件 | 用途 | 路径 |
|------|------|------|
| **menu.bat** | 交互式菜单 | `bettafish/Windows/menu.bat` |
| **deploy.bat** | 快速部署 | `bettafish/Windows/deploy.bat` |
| **fix-all.bat** | 智能修复 | `bettafish/Windows/fix-all.bat` |
| **scripts/menu.ps1** | 菜单脚本 | `bettafish/Windows/scripts/menu.ps1` |
| **scripts/fix-all.ps1** | 修复脚本 | `bettafish/Windows/scripts/fix-all.ps1` |
| **README.md** | 使用说明 | `bettafish/Windows/README.md` |

### 仓库级文件

| 文件 | 用途 | 路径 |
|------|------|------|
| **README.md** | 仓库主说明 | `README.md` |
| **QUICK_REFERENCE.md** | 本文件 | `QUICK_REFERENCE.md` |
| **LICENSE** | MIT 许可证 | `LICENSE` |

---

## 🔍 关键设计理念

### 1. 跨平台统一体验

- **目标**: 让 Windows、macOS、Linux 用户获得一致的部署体验
- **实现**:
  - Linux/macOS: Shell 脚本 (.sh)
  - Windows: BAT 包装器 + PowerShell 脚本
  - 都提供交互式菜单和一键部署

### 2. 用户友好优先

- **目标**: 无需技术背景即可使用
- **实现**:
  - Windows: 双击 .bat 文件即可
  - macOS/Linux: 简单的 `./script.sh`
  - 详细的提示和错误信息
  - 智能诊断和自动修复

### 3. Windows Plan C 结构

```
Windows/
├── menu.bat                # 入口文件（双击运行）
├── deploy.bat              # 快速部署（双击运行）
├── fix-all.bat             # 智能修复（双击运行）
└── scripts/                # PowerShell 脚本目录
    ├── menu.ps1            # 菜单逻辑
    ├── docker-deploy.ps1   # 部署逻辑
    └── fix-all.ps1         # 修复逻辑
```

**优势**:
- ✅ 用户看到的文件简洁
- ✅ 核心逻辑集中管理
- ✅ BAT 文件仅做权限和路径处理
- ✅ PowerShell 脚本包含所有业务逻辑

---

## 🐛 常见问题和解决方案

### Q: 推送到 GitHub 后用户看不到更新？

**A**: GitHub CDN 缓存，通常 5-10 分钟刷新

```bash
# 检查文件是否已更新
curl -I https://raw.githubusercontent.com/Jascenn/deployment-scripts-hub/main/README.md

# 提醒用户清理本地缓存
git clone https://github.com/Jascenn/deployment-scripts-hub.git --depth 1
```

### Q: Windows 脚本出现编码问题？

**A**: 使用 fix-all.bat 自动修复

```batch
双击 bettafish\Windows\fix-all.bat
```

或手动检查编码：
```powershell
# 所有 PowerShell 脚本必须是 UTF-8 with BOM
Get-Content scripts\*.ps1 -Encoding UTF8
```

### Q: 如何测试部署工具？

**A**: 在临时目录测试

```bash
# Linux/macOS
cd /tmp
git clone https://github.com/Jascenn/deployment-scripts-hub.git test-deploy
cd test-deploy/bettafish/Linux_macOS
./docker-deploy.sh

# Windows
# 克隆到 C:\Temp\test-deploy
# 然后运行工具
```

### Q: 如何查看用户使用日志？

**A**: 脚本会生成日志文件

```bash
# Linux/macOS
cat ~/BettaFish-main/deployment.log

# Windows
type %USERPROFILE%\BettaFish-main\deployment.log
```

---

## 📊 版本历史

| 版本 | 日期 | 更新内容 |
|------|------|---------|
| **v1.0** | 2025-11-16 | 重构为部署工具集合仓库 |
| | | 分离 Linux_macOS 和 Windows 工具 |
| | | 实施 Plan C 结构（Windows） |
| | | 添加智能修复工具 fix-all |
| | | 完整的跨平台支持 |

---

## 🎯 下一步计划

### 短期（当前周期）

- [x] 更新 README.md 为工具集合仓库定位
- [x] 更新 QUICK_REFERENCE.md
- [ ] 创建 Release v1.0
- [ ] 添加使用演示截图

### 中期（未来 1-2 月）

- [ ] 添加第二个项目的部署工具
- [ ] 创建项目模板
- [ ] 添加 CI/CD 自动测试
- [ ] 创建 Web 文档页面

### 长期（远期规划）

- [ ] 开发 CLI 工具
- [ ] 支持更多部署平台
- [ ] 建立社区贡献流程
- [ ] 多语言文档支持

---

## 📞 联系方式

### 维护者信息

- **维护者**: LingYi（凌一）
- **邮箱**: darkerrouge@gmail.com
- **博客**: https://lingyi.bio
- **GitHub**: [@Jascenn](https://github.com/Jascenn)

### 项目链接

- **GitHub仓库**: https://github.com/Jascenn/deployment-scripts-hub
- **Issues**: https://github.com/Jascenn/deployment-scripts-hub/issues
- **Pull Requests**: https://github.com/Jascenn/deployment-scripts-hub/pulls

### 相关资源

- **BettaFish项目**: https://github.com/666ghj/BettaFish
- **VibeCoding API**: https://vibecodingapi.ai
- **LIONCC.AI**: https://lioncc.ai

---

## 🎉 当前状态

✅ **仓库已上线** - v1.0

✅ **BettaFish 跨平台工具包完整**

✅ **文档完善**

✅ **测试通过**

✅ **持续维护中**

---

**最后更新**: 2025-11-16

**分享链接**: https://github.com/Jascenn/deployment-scripts-hub

**博客文章**: https://codecodex.ai/2025-11-16/bettafish-cross-platform-deployment-toolkit.html
