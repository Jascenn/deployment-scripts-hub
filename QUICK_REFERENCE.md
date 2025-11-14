# 🎯 Quick Reference - Deployment Scripts Hub

> 快速参考卡片 - 常用命令和链接

---

## 📦 仓库信息

- **GitHub**: https://github.com/Jascenn/deployment-scripts-hub
- **本地**: `/Users/jascen/Development/deployment-scripts-hub`
- **状态**: ✅ 已上线

---

## 🚀 用户使用（分享给别人）

### BettaFish 一键部署

```bash
# 基础部署
curl -fsSL https://raw.githubusercontent.com/Jascenn/deployment-scripts-hub/main/bettafish/install.sh | bash

# 使用代理
curl -fsSL https://raw.githubusercontent.com/Jascenn/deployment-scripts-hub/main/bettafish/install.sh | bash -s -- --proxy http://127.0.0.1:7890

# 指定目录
curl -fsSL https://raw.githubusercontent.com/Jascenn/deployment-scripts-hub/main/bettafish/install.sh | bash -s -- --dir ~/my-bettafish

# 查看帮助
curl -fsSL https://raw.githubusercontent.com/Jascenn/deployment-scripts-hub/main/bettafish/install.sh | bash -s -- --help
```

---

## 🔧 维护者操作（您自己使用）

### 更新脚本

```bash
cd /Users/jascen/Development/deployment-scripts-hub

# 修改文件
nano bettafish/install.sh
# 或
nano bettafish/docker-deploy.sh

# 提交
git add .
git commit -m "Update: description of changes"
git push

# 用户自动获得更新（CDN 缓存约 5-10 分钟）
```

### 测试脚本

```bash
# 测试帮助
curl -fsSL https://raw.githubusercontent.com/Jascenn/deployment-scripts-hub/main/bettafish/install.sh | bash -s -- --help

# 本地测试（完整交互式体验）
cd /tmp
curl -fsSL https://raw.githubusercontent.com/Jascenn/deployment-scripts-hub/main/bettafish/install.sh -o test-install.sh
chmod +x test-install.sh
./test-install.sh --dir /tmp/test-bettafish
```

### 查看 Git 状态

```bash
cd /Users/jascen/Development/deployment-scripts-hub
git status
git log --oneline -5
```

### 添加新项目

```bash
cd /Users/jascen/Development/deployment-scripts-hub

# 1. 复制模板
cp -r project-template newproject

# 2. 修改脚本
cd newproject
mv smart-deploy.sh.template install.sh
nano install.sh

# 3. 创建 README
cp ../bettafish/README.md README.md
nano README.md

# 4. 提交
cd ..
git add newproject
git commit -m "Add newproject deployment scripts"
git push
```

---

## 📂 重要文件

| 文件 | 用途 | 位置 |
|------|------|------|
| **install.sh** | 一键安装包装脚本 | `bettafish/install.sh` |
| **docker-deploy.sh** | 完整部署脚本（2595行） | `bettafish/docker-deploy.sh` |
| **docker-cleanup.sh** | 清理脚本 | `bettafish/docker-cleanup.sh` |
| **README.md** | 项目说明 | `bettafish/README.md` |
| **部署完成说明.md** | 完整部署文档 | `部署完成说明.md` |
| **仓库设置指南.md** | GitHub 设置步骤 | `仓库设置指南.md` |
| **快速开始.md** | 快速上手 | `快速开始.md` |

---

## 🔍 关键逻辑

### TTY 检测（install.sh:249-275）

```bash
if [ -t 0 ] && [ -t 1 ]; then
    # 交互式终端 → 直接执行 docker-deploy.sh
    bash ./docker-deploy.sh
else
    # 非交互式（curl 管道）→ 提示用户手动执行
    echo "cd $DEPLOY_DIR/BettaFish-main && ./docker-deploy.sh"
    exit 0
fi
```

### 为什么这样设计？

- `docker-deploy.sh` 有完整的交互式功能：
  - 🎨 进度条
  - 🌐 网络速度测试
  - 💬 用户交互提示
  - 🎨 彩色输出

- 这些功能需要真实的 TTY（终端）才能正常显示

- `curl | bash` 没有 TTY，所以引导用户在终端执行

---

## 🐛 常见问题

### Q: curl 下载返回 404

**A**: GitHub Raw CDN 缓存，等待 5-10 分钟

```bash
# 检查文件是否存在
curl -I https://raw.githubusercontent.com/Jascenn/deployment-scripts-hub/main/bettafish/install.sh
```

### Q: 修改后用户还是看到旧版本

**A**: CDN 缓存，等待或者清理本地缓存

```bash
# 强制刷新（添加时间戳）
curl -fsSL "https://raw.githubusercontent.com/Jascenn/deployment-scripts-hub/main/bettafish/install.sh?$(date +%s)" | bash
```

### Q: 如何查看用户执行日志？

**A**: 让用户添加 `set -x` 调试：

```bash
curl -fsSL https://raw.githubusercontent.com/Jascenn/deployment-scripts-hub/main/bettafish/install.sh | bash -x
```

### Q: 如何在 Gitee 镜像？

**A**:

```bash
cd /Users/jascen/Development/deployment-scripts-hub

# 添加 Gitee 远程
git remote add gitee https://gitee.com/YOUR_USERNAME/deployment-scripts-hub.git

# 推送
git push gitee main
```

---

## 📊 版本历史

| 版本 | 日期 | 更新内容 |
|------|------|---------|
| **v2.1** | 2025-01-14 | 初始发布，一键部署支持 |
| | | TTY 智能检测 |
| | | 代理配置支持 |
| | | 完整交互式体验 |

---

## 🎯 下一步计划

### 短期（可选）

- [ ] 添加 Gitee 镜像（加速国内访问）
- [ ] 创建 Release（v2.1）
- [ ] 向 BettaFish 官方提交 PR
- [ ] 添加使用统计（可选）

### 中期（可选）

- [ ] 添加更多项目部署脚本
- [ ] 创建 Web 文档页面
- [ ] 添加部署视频教程
- [ ] 创建 Docker 镜像

### 长期（可选）

- [ ] 开发 CLI 工具
- [ ] 支持更多部署平台
- [ ] 社区贡献指南
- [ ] 自动化测试

---

## 📞 联系方式

- **GitHub Issues**: https://github.com/Jascenn/deployment-scripts-hub/issues
- **Pull Requests**: https://github.com/Jascenn/deployment-scripts-hub/pulls
- **BettaFish 官方**: https://github.com/666ghj/BettaFish

---

## 🎉 当前状态

✅ **仓库已上线**

✅ **一键部署可用**

✅ **文档完整**

✅ **测试通过**

---

**最后更新**: 2025-01-14

**维护者**: Claude Code

**分享链接**: https://github.com/Jascenn/deployment-scripts-hub
