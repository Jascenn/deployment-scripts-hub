# 🐳 Docker Desktop 启动指南

## 问题现象

运行 `docker-deploy.bat` 时看到：

```
⚠️  Docker Desktop 未运行
ℹ️  正在尝试启动 Docker Desktop...
ℹ️  等待 Docker Desktop 启动（这可能需要 30-60 秒）...
```

然后等待很久...

## 🎯 新的交互式选项（v3.8.4）

现在脚本会询问你的选择：

```
⚠️  Docker Desktop 未运行

请选择操作:
  1. 我已经手动启动了 Docker Desktop，继续检测
  2. 让脚本自动启动 Docker Desktop
  3. 退出脚本，稍后重试

请输入选项 (1/2/3):
```

## 📋 选项说明

### 选项 1: 我已经手动启动了 Docker Desktop

**适用场景**:
- 你已经从开始菜单启动了 Docker Desktop
- Docker 正在启动中（右下角图标显示动画）
- 你想让脚本等待 Docker 完全就绪

**操作**:
```
请输入选项 (1/2/3): 1
```

**脚本会做什么**:
- 每 5 秒检测一次 Docker 状态
- 显示等待时间
- 最多等待 60 秒
- Docker 就绪后自动继续

**输出示例**:
```
ℹ️  正在检测 Docker 服务...

等待 Docker 就绪... (5 秒)
等待 Docker 就绪... (10 秒)
等待 Docker 就绪... (15 秒)
✅ Docker Desktop 已就绪
```

---

### 选项 2: 让脚本自动启动 Docker Desktop

**适用场景**:
- Docker Desktop 完全关闭
- 你想让脚本自动处理启动

**操作**:
```
请输入选项 (1/2/3): 2
```

**脚本会做什么**:
- 自动运行 `C:\Program Files\Docker\Docker\Docker Desktop.exe`
- 显示启动进度（百分比）
- 最多等待 90 秒
- 提示你观察右下角图标

**输出示例**:
```
ℹ️  正在尝试启动 Docker Desktop...
ℹ️  等待 Docker Desktop 启动（约 30-60 秒）...
ℹ️  提示: 你可以在右下角看到 Docker 图标

等待中... 5 秒 / 90 秒 [5%]
等待中... 10 秒 / 90 秒 [11%]
等待中... 15 秒 / 90 秒 [16%]
...
等待中... 45 秒 / 90 秒 [50%]

✅ Docker Desktop 已启动
```

---

### 选项 3: 退出脚本，稍后重试

**适用场景**:
- 你想先手动启动 Docker 并等待完全就绪
- 系统资源紧张，需要先关闭其他程序
- 需要先解决 Docker 配置问题

**操作**:
```
请输入选项 (1/2/3): 3
```

**脚本会做什么**:
- 立即退出
- 显示友好提示

**输出示例**:
```
ℹ️  脚本已退出
ℹ️  请手动启动 Docker Desktop 后重新运行
```

## 🚀 推荐流程

### 快速部署（推荐）

1. **先手动启动 Docker Desktop**
   ```
   开始菜单 → 搜索 "Docker Desktop" → 点击启动
   ```

2. **观察右下角图标**
   - 等待图标从灰色/动画变为绿色
   - 绿色 = Docker 已完全启动

3. **运行部署脚本**
   ```cmd
   docker-deploy.bat
   ```

4. **选择选项 1**
   ```
   请输入选项 (1/2/3): 1
   ```

5. **脚本会立即检测到 Docker 就绪**
   ```
   ✅ Docker Desktop 已就绪
   ```

### 完全自动化

1. **直接运行部署脚本**
   ```cmd
   docker-deploy.bat
   ```

2. **选择选项 2**
   ```
   请输入选项 (1/2/3): 2
   ```

3. **等待 Docker 自动启动**
   - 观看进度百分比
   - 大约 30-60 秒

4. **继续部署**

## ⏱️ Docker Desktop 启动时间

典型启动时间：

| 场景 | 预期时间 | 说明 |
|------|---------|------|
| 首次启动 | 1-2 分钟 | WSL2 初始化 |
| 正常启动 | 30-60 秒 | 标准情况 |
| SSD + 高配置 | 15-30 秒 | 快速启动 |
| HDD + 低配置 | 2-3 分钟 | 可能较慢 |

## 🔍 如何判断 Docker 已就绪？

### 方法 1: 查看右下角图标

```
❌ 灰色图标 → Docker 未启动
🔄 动画图标 → Docker 正在启动
✅ 绿色图标 → Docker 已就绪
```

### 方法 2: 打开 Docker Desktop 窗口

```
点击右下角 Docker 图标 → 打开 Dashboard

看到 "Docker Desktop is running" = 就绪
看到 "Docker Desktop is starting..." = 启动中
```

### 方法 3: 命令行测试

```powershell
docker ps
```

**输出示例 - 已就绪**:
```
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
(空表格，但没有错误信息)
```

**输出示例 - 未就绪**:
```
error during connect: This error may indicate that the docker daemon is not running.
```

## ⚠️ 常见问题

### Q1: 等待超时怎么办？

**现象**:
```
❌ Docker Desktop 启动超时
ℹ️  可能原因：
  1. Docker Desktop 启动时间较长（尤其是首次启动）
  2. 系统资源不足
  3. WSL2 未正确配置
```

**解决方法**:

**步骤 1**: 手动启动并观察
```
1. 关闭脚本（Ctrl+C）
2. 手动从开始菜单启动 Docker Desktop
3. 打开 Docker Desktop 窗口观察启动日志
4. 等待完全启动（绿色图标）
5. 重新运行部署脚本
6. 选择选项 1
```

**步骤 2**: 检查 WSL2
```powershell
# 检查 WSL2 状态
wsl --status

# 如果 WSL2 未安装，参考官方文档：
# https://docs.microsoft.com/zh-cn/windows/wsl/install
```

**步骤 3**: 检查系统资源
```
任务管理器 → 性能

确保：
- 可用内存 > 4GB
- CPU 使用率 < 80%
- 磁盘 I/O 正常
```

---

### Q2: Docker Desktop 图标一直显示动画？

**可能原因**:
1. WSL2 未启动
2. Hyper-V 冲突
3. 防病毒软件阻止

**解决方法**:

**检查 WSL2**:
```powershell
wsl --list --verbose
```

预期看到：
```
  NAME                   STATE           VERSION
* docker-desktop         Running         2
  docker-desktop-data    Running         2
```

**重启 Docker Desktop**:
```
右键 Docker 图标 → Quit Docker Desktop
等待 10 秒
开始菜单 → Docker Desktop → 启动
```

---

### Q3: 脚本找不到 Docker Desktop？

**错误信息**:
```
❌ 找不到 Docker Desktop 可执行文件
ℹ️  预期路径: C:\Program Files\Docker\Docker\Docker Desktop.exe
```

**解决方法**:

**检查安装路径**:
```powershell
# 检查默认路径
Test-Path "C:\Program Files\Docker\Docker\Docker Desktop.exe"

# 如果返回 False，查找实际路径
Get-ChildItem -Path "C:\Program Files" -Recurse -Filter "Docker Desktop.exe" -ErrorAction SilentlyContinue
```

**如果安装在其他位置**:
- 手动启动 Docker Desktop
- 运行部署脚本
- 选择选项 1

---

## 💡 提示和技巧

### 技巧 1: 设置 Docker Desktop 开机自启

```
Docker Desktop 设置 → General → Start Docker Desktop when you log in
```

这样每次开机 Docker 都会自动启动。

### 技巧 2: 使用 Docker Desktop 快捷方式

创建桌面快捷方式：
```
右键桌面 → 新建 → 快捷方式
目标: C:\Program Files\Docker\Docker\Docker Desktop.exe
名称: Docker Desktop
```

### 技巧 3: 检查 Docker Desktop 日志

如果启动异常：
```
%APPDATA%\Docker\log.txt
```

查看详细错误信息。

---

## 📝 更新日志

**v3.8.4** (2025-11-15)
- ✅ 添加交互式选项（1/2/3）
- ✅ 优化等待时间显示
- ✅ 增加进度百分比
- ✅ 超时时间延长到 90 秒
- ✅ 更详细的错误提示

**v3.8.3** (2025-11-15)
- 自动启动 Docker Desktop
- 固定 60 秒超时

---

**建议**: 如果你经常需要部署，建议设置 Docker Desktop 开机自启，这样每次运行脚本都能立即检测到 Docker 已就绪。

**文档**: [README-Windows.md](README-Windows.md) | [START-HERE.md](START-HERE.md)
