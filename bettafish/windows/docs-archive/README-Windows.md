# BettaFish Windows 一键部署指南

## ⚠️ 首次使用必读

**如果遇到中文乱码或编码错误，请先运行 `fix-encoding.bat` 修复文件编码！**

详细说明：[ENCODING-FIX-REQUIRED.md](ENCODING-FIX-REQUIRED.md)

---

## 📋 系统要求

- **操作系统**: Windows 10 / Windows 11 / Windows Server 2016+
- **PowerShell**: 版本 5.1 或更高
- **Docker Desktop**: 最新版本
- **管理员权限**: 需要配置防火墙和系统设置

## 🚀 快速开始

### 方法一：双击运行（推荐）

1. **下载部署包**
   ```
   BettaFish-Deployment-Kit/
   └── Windows-Version/
       ├── docker-deploy.bat      ← 双击这个文件
       ├── docker-deploy.ps1
       └── BettaFish-main/
   ```

2. **双击 `docker-deploy.bat`**
   - 脚本会自动请求管理员权限
   - 自动检测并启动 Docker Desktop
   - 按提示输入 API 密钥即可完成部署

### 方法二：命令行运行

```cmd
# 在 Windows-Version 目录下执行
docker-deploy.bat
```

或直接运行 PowerShell 脚本：

```powershell
# 以管理员身份打开 PowerShell
powershell -ExecutionPolicy Bypass -File docker-deploy.ps1
```

## 🔧 部署流程

脚本会自动完成以下步骤：

1. **环境检测** (约 10 秒)
   - 检查 PowerShell 版本
   - 检测 Docker Desktop 安装状态
   - 自动启动 Docker Desktop（如未运行）
   - 验证网络连接

2. **项目检测** (约 5 秒)
   - 查找 BettaFish-main 目录
   - 验证 docker-compose.yml 存在

3. **API 配置** (人工输入)
   - 输入 OpenAI API Key（必填）
   - 输入 Firecrawl API Key（可选）

4. **环境配置** (约 5 秒)
   - 自动生成 .env 文件
   - 配置数据库参数

5. **镜像管理** (约 2-5 分钟)
   - 检查本地镜像
   - 自动拉取 PostgreSQL 镜像
   - 自动拉取 BettaFish 镜像
   - 询问是否更新已有镜像

6. **服务部署** (约 30 秒)
   - 自动检测端口可用性
   - 处理端口冲突（5000 → 5001-5010）
   - 启动 Docker 容器
   - 等待服务就绪

7. **网络配置** (约 10 秒)
   - 自动配置 Windows 防火墙
   - 开放必要端口
   - 检测本地/公网 IP
   - 显示访问地址

## 🌍 访问服务

部署完成后，脚本会显示访问地址：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  访问地址
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  本地访问:
    http://localhost:5000

  局域网访问:
    http://192.168.1.100:5000

  公网访问:
    http://101.37.75.125:5000

  Streamlit 服务:
    Insight Engine:  http://localhost:8501
    Media Engine:    http://localhost:8502
    Query Engine:    http://localhost:8503
```

## 🛡️ Windows 防火墙

脚本会自动配置防火墙规则：

- **主服务端口**: 5000-5010（根据实际使用端口）
- **Streamlit 服务**: 8501、8502、8503

如果自动配置失败，请手动配置：

1. 打开 **Windows 防火墙** → **高级设置**
2. 选择 **入站规则** → **新建规则**
3. 规则类型：**端口**
4. 协议：**TCP**
5. 端口：输入实际使用的端口号
6. 操作：**允许连接**
7. 配置文件：**全部勾选**
8. 名称：`BettaFish Main Service`

## 📊 端口冲突处理

脚本内置智能端口检测：

| 默认端口 | 备选范围 | 说明 |
|---------|---------|-----|
| 5000 | 5001-5010 | 主服务端口 |
| 8501-8503 | - | Streamlit 服务（固定） |

**自动处理流程**：
1. 检测 5000 端口是否可用
2. 如果被占用，自动尝试 5001-5010
3. 找到可用端口后自动更新配置
4. 防火墙规则自动适配实际端口

## 🔍 常用管理命令

所有命令需要在 `BettaFish-main` 目录下执行：

```powershell
# 查看服务状态
docker-compose ps

# 查看服务日志
docker-compose logs -f

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 更新并重启服务
docker-compose pull
docker-compose up -d
```

## ❓ 常见问题

### 1. PowerShell 执行策略限制

**问题**: "无法加载文件，因为在此系统上禁止运行脚本"

**解决方案**:
- 使用 `docker-deploy.bat`（已自动绕过）
- 或手动设置：
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```

### 2. Docker Desktop 未启动

**现象**: 脚本提示 "Docker Desktop 未运行"

**解决方案**:
- 脚本会自动尝试启动 Docker Desktop
- 如果失败，请手动启动后重新运行脚本

### 3. 权限不足

**现象**: 防火墙配置失败

**解决方案**:
- 右键 `docker-deploy.bat` → **以管理员身份运行**
- 或在管理员 PowerShell 中运行脚本

### 4. 端口冲突

**现象**: 服务启动失败，提示端口被占用

**解决方案**:
- 脚本会自动处理端口冲突
- 如果 5000-5010 全部被占用，请手动停止其他服务

### 5. 网络超时

**现象**: 镜像拉取超时

**解决方案**:
- 检查网络连接
- 配置 Docker Desktop 镜像加速器
- 使用国内镜像源（脚本自动处理）

## 🔒 云服务器部署

如果在云服务器上部署，还需要配置安全组：

### 阿里云 ECS

1. 登录控制台 → **安全组** → **配置规则**
2. 添加入方向规则：
   - 端口：实际使用端口（如 5001）
   - 授权对象：`0.0.0.0/0`
   - 描述：BettaFish 主服务

### 腾讯云 CVM

1. 登录控制台 → **安全组** → **入站规则**
2. 添加规则：
   - 协议端口：`TCP:5001`
   - 来源：`0.0.0.0/0`

详细配置请参考：[云服务器安全组配置](../docs/solutions/cloud-security.md)

## 📝 日志文件

脚本运行日志保存在：

```
Windows-Version/
└── logs/
    └── deploy_YYYYMMDD_HHmmss.log
```

如遇问题，请查看日志文件获取详细错误信息。

## 🆘 获取帮助

- **GitHub Issues**: [提交问题](https://github.com/your-repo/BettaFish-Deployment-Kit/issues)
- **文档中心**: [查看完整文档](../README.md)
- **常见问题**: [FAQ](../docs/FAQ.md)

## 📄 许可证

本项目采用 MIT 许可证，详见 [LICENSE](../LICENSE)。

---

**更新时间**: 2025-11-15
**版本**: v3.8.3-windows
**作者**: LIONCC.AI
