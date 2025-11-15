# 📦 BettaFish 项目下载和设置指南

根据诊断结果，你需要：
1. ✅ 启动 Docker Desktop
2. ✅ 下载 BettaFish-main 项目源码

## 步骤 1: 启动 Docker Desktop

### 检查 Docker Desktop 状态

诊断显示：
```
[✓] Docker Desktop - Docker version 28.5.1, build e180ab8
[✗] Docker 服务  ← Docker 未运行
```

### 解决方法

**方法一：手动启动**
1. 在 Windows 开始菜单搜索 "Docker Desktop"
2. 点击启动
3. 等待 Docker Desktop 完全启动（右下角图标变为绿色）

**方法二：让部署脚本自动启动**
- 直接运行 `docker-deploy.bat`
- 脚本会自动检测并启动 Docker Desktop
- 等待 60 秒让 Docker 完全启动

## 步骤 2: 下载 BettaFish-main 项目源码

诊断显示：
```
[✗] BettaFish-main 目录 - C:\Users\12863\OneDrive\Downloads\BettaFish-Deployment-Kit\Windows-Version\BettaFish-main
```

### 方法一：从 GitHub 下载（推荐）

1. **访问 GitHub 仓库**
   ```
   https://github.com/JasonZ93/BettaFish
   ```

2. **下载源码**
   - 点击绿色的 "Code" 按钮
   - 选择 "Download ZIP"
   - 下载 `BettaFish-main.zip`

3. **解压到正确位置**
   ```
   解压后将文件夹重命名为 BettaFish-main

   目标位置：
   C:\Users\12863\OneDrive\Downloads\BettaFish-Deployment-Kit\Windows-Version\BettaFish-main
   ```

4. **验证目录结构**
   ```
   Windows-Version/
   ├── docker-deploy.bat
   ├── diagnose.bat
   └── BettaFish-main/              ← 必须在这里
       ├── docker-compose.yml       ← 必须存在
       ├── app/
       ├── streamlit_apps/
       └── ...
   ```

### 方法二：使用 Git Clone（开发者）

如果你安装了 Git：

```powershell
# 进入 Windows-Version 目录
cd C:\Users\12863\OneDrive\Downloads\BettaFish-Deployment-Kit\Windows-Version

# 克隆仓库
git clone https://github.com/JasonZ93/BettaFish.git BettaFish-main

# 或者使用国内镜像（如果 GitHub 慢）
git clone https://gitee.com/mirrors/BettaFish.git BettaFish-main
```

### 方法三：从部署包获取（离线）

如果有完整的部署包：

```
BettaFish-Deployment-Kit.zip
└── 解压后应该已经包含 BettaFish-main/
```

## 步骤 3: 验证设置

### 运行诊断工具验证

```cmd
cd C:\Users\12863\OneDrive\Downloads\BettaFish-Deployment-Kit\Windows-Version
diagnose.bat
```

**预期结果**：
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 2. 项目文件检查
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[✓] BettaFish-main 目录  ← 应该显示 ✓
[✓] docker-compose.yml
```

## 步骤 4: 开始部署

一切就绪后，运行部署脚本：

```cmd
docker-deploy.bat
```

部署脚本会自动：
1. ✅ 检测到 Docker Desktop 未运行 → 自动启动
2. ✅ 找到 BettaFish-main 目录
3. ✅ 请求管理员权限（UAC 弹窗）
4. ✅ 询问 API 密钥配置
5. ✅ 拉取 Docker 镜像
6. ✅ 启动服务
7. ✅ 配置防火墙
8. ✅ 显示访问地址

## 常见问题

### Q1: Docker Desktop 启动慢怎么办？

**A**: Docker Desktop 首次启动可能需要 1-2 分钟，请耐心等待。看到右下角图标变为绿色即表示启动完成。

---

### Q2: 下载 GitHub 仓库很慢怎么办？

**A**: 使用以下方法：
1. 使用 Gitee 镜像（国内访问快）
2. 使用 GitHub 加速服务（如 ghproxy.com）
3. 联系项目维护者获取离线包

---

### Q3: OneDrive 同步导致问题？

**A**: OneDrive 可能会干扰 Docker 文件访问，建议：

**方案 1**: 将项目移到本地磁盘
```powershell
# 复制到本地
xcopy /E /I "C:\Users\12863\OneDrive\Downloads\BettaFish-Deployment-Kit" "C:\BettaFish-Deployment-Kit"

# 进入本地目录
cd C:\BettaFish-Deployment-Kit\Windows-Version

# 运行部署
docker-deploy.bat
```

**方案 2**: 排除 BettaFish 文件夹同步
1. 右键 OneDrive 图标
2. 设置 → 同步和备份 → 管理备份
3. 排除 BettaFish-Deployment-Kit 文件夹

---

### Q4: 目录结构不对怎么办？

**A**: 确保最终结构如下：
```
Windows-Version/
├── docker-deploy.bat
├── docker-deploy.ps1
├── diagnose.bat
├── diagnose.ps1
└── BettaFish-main/          ← 与 .bat 文件同级
    ├── docker-compose.yml   ← 必须存在
    ├── .env                 ← 部署时自动生成
    ├── app/
    ├── streamlit_apps/
    └── requirements.txt
```

如果结构不对（例如多了一层目录）：
```
# 错误的结构
Windows-Version/
└── BettaFish-main/
    └── BettaFish-main/      ← 多了一层
        └── docker-compose.yml

# 正确做法：将内层的 BettaFish-main 移到外面
```

## 下一步

完成以上步骤后：

1. ✅ Docker Desktop 已启动
2. ✅ BettaFish-main 目录已就位
3. ✅ 目录结构正确

**现在运行**：
```cmd
docker-deploy.bat
```

开始自动化部署！🚀

---

**需要帮助？**
- 查看：[START-HERE.md](START-HERE.md)
- 测试指南：[TEST-GUIDE.md](TEST-GUIDE.md)
- 完整文档：[README-Windows.md](README-Windows.md)
