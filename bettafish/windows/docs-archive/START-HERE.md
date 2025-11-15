# 🚀 Windows 版本快速启动指南

## 📦 首次使用三步走

### 第一步：修复文件编码（必需）

由于跨平台开发原因，PowerShell 脚本需要转换编码才能正确显示中文。

**双击运行**:
```
fix-encoding.bat
```

等待 3 秒，看到 "Encoding fix completed!" 即完成。

### 第二步：运行诊断工具（推荐）

检查系统环境是否就绪：

**双击运行**:
```
diagnose.bat
```

诊断工具会检查：
- ✅ PowerShell 版本
- ✅ Docker Desktop 安装状态
- ✅ 网络连接
- ✅ 端口占用情况

### 第三步：开始部署

一切就绪后，开始部署：

**双击运行**:
```
docker-deploy.bat
```

按提示输入 API 密钥，等待部署完成。

## 📂 文件说明

```
Windows-Version/
├── START-HERE.md              ← 你正在看的文件
│
├── 🔧 编码修复工具（首次使用）
│   ├── fix-encoding.bat       ← 修复文件编码（首次必须运行）
│   └── fix-encoding.ps1
│
├── 🚀 部署工具
│   ├── docker-deploy.bat      ← 主部署脚本
│   └── docker-deploy.ps1
│
├── 🔍 诊断工具
│   ├── diagnose.bat           ← 环境诊断
│   └── diagnose.ps1
│
├── 📖 文档
│   ├── README-Windows.md      ← 完整使用指南
│   ├── ENCODING-FIX-REQUIRED.md ← 编码问题详解
│   ├── TEST-GUIDE.md          ← 测试指南
│   ├── WINDOWS_ANALYSIS.md    ← 技术分析
│   └── COMPLETION_SUMMARY.md  ← 开发总结
│
└── BettaFish-main/            ← 项目源码（需要下载）
```

## ❓ 常见问题速查

### 问题 1: 看到中文乱码

```
Unexpected token '鏈幏鍙栵紙鏌愪簺鍔熻兘鍙楅檺锛?' ...
```

**解决**: 运行 `fix-encoding.bat`

---

### 问题 2: Docker Desktop 未运行

```
[✗] Docker 服务 - 未运行
```

**解决**:
1. 手动启动 Docker Desktop
2. 或者脚本会自动启动（等待 60 秒）

---

### 问题 3: 找不到 BettaFish-main 目录

```
[错误] 未找到 BettaFish-main 目录
```

**解决**: 确保目录结构如下：
```
Windows-Version/
├── docker-deploy.bat
└── BettaFish-main/          ← 必须在同一级
    └── docker-compose.yml
```

---

### 问题 4: 端口被占用

```
[警告] 端口 5000 已被占用
```

**解决**: 脚本会自动切换到 5001-5010，无需手动处理。

---

### 问题 5: 权限不足

```
防火墙配置失败
```

**解决**: 右键 `docker-deploy.bat` → "以管理员身份运行"

## 🎯 成功部署后

看到以下输出表示部署成功：

```
==========================================
   BettaFish 部署完成！
==========================================

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  访问地址
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  本地访问:
    http://localhost:5000

  局域网访问:
    http://192.168.1.100:5000

  公网访问:
    http://101.37.75.125:5000
```

在浏览器打开任意一个地址即可使用。

## 🛠️ 管理命令

进入 `BettaFish-main` 目录执行：

```powershell
# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down

# 重启服务
docker-compose restart
```

## 📞 需要帮助？

1. **查看完整文档**: [README-Windows.md](README-Windows.md)
2. **编码问题**: [ENCODING-FIX-REQUIRED.md](ENCODING-FIX-REQUIRED.md)
3. **测试指南**: [TEST-GUIDE.md](TEST-GUIDE.md)
4. **提交问题**: GitHub Issues

## ✅ 快速检查清单

部署前确认：

- [ ] 已运行 `fix-encoding.bat` 修复编码
- [ ] Windows 10/11 或 Windows Server
- [ ] PowerShell 5.1 或更高
- [ ] Docker Desktop 已安装
- [ ] 有管理员权限
- [ ] 网络连接正常
- [ ] 已准备好 OpenAI API Key

全部勾选后，开始部署！

---

**版本**: v3.8.3-windows
**更新**: 2025-11-15
**作者**: LIONCC.AI
