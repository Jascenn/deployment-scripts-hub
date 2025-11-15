# 离线安装包目录

本目录用于存放 Docker 镜像的离线安装包，适用于无网络或网络受限的环境。

## 📦 目录用途

在网络条件良好时预先下载 Docker 镜像，保存为离线包，方便在无网络环境下部署。

## 💾 支持的离线包

### BettaFish 主镜像
```
bettafish-latest.tar          # BettaFish 主程序镜像 (~2-3GB)
```

### 数据库镜像
```
postgres-15-alpine.tar        # PostgreSQL 数据库镜像 (~250MB)
```

## 📥 创建离线包

### 方法 1：使用脚本（推荐）

```powershell
# 在有网络的环境下运行
.\download-offline-packages.ps1
```

### 方法 2：手动创建

```powershell
# 1. 拉取镜像
docker pull ghcr.io/666ghj/bettafish:latest
docker pull postgres:15-alpine

# 2. 保存为离线包
docker save -o offline-packages\bettafish-latest.tar ghcr.io/666ghj/bettafish:latest
docker save -o offline-packages\postgres-15-alpine.tar postgres:15-alpine

# 3. 压缩（可选，节省空间）
Compress-Archive -Path offline-packages\*.tar -DestinationPath offline-packages.zip
```

## 📤 使用离线包

### 自动加载（推荐）

部署脚本会自动检测并加载离线包：

```powershell
.\docker-deploy.bat
# 或
.\docker-deploy.ps1
```

### 手动加载

```powershell
# 加载 BettaFish 镜像
docker load -i offline-packages\bettafish-latest.tar

# 加载数据库镜像
docker load -i offline-packages\postgres-15-alpine.tar

# 验证镜像已加载
docker images
```

## 📋 离线包清单

| 文件名 | 大小 | 说明 |
|--------|------|------|
| `bettafish-latest.tar` | ~2-3GB | BettaFish 主镜像 |
| `postgres-15-alpine.tar` | ~250MB | PostgreSQL 数据库 |

## 🔄 更新离线包

当 BettaFish 发布新版本时：

```powershell
# 1. 删除旧的离线包
Remove-Item offline-packages\bettafish-latest.tar

# 2. 拉取最新镜像
docker pull ghcr.io/666ghj/bettafish:latest

# 3. 保存新的离线包
docker save -o offline-packages\bettafish-latest.tar ghcr.io/666ghj/bettafish:latest
```

## 💡 使用场景

### 适用情况

- ✅ 无网络环境部署
- ✅ 网络速度慢，预先下载
- ✅ 多台机器批量部署
- ✅ 网络受限（防火墙/代理）

### 不适用情况

- ❌ 网络正常（直接在线部署更方便）
- ❌ 需要最新版本（离线包可能不是最新）

## 📝 注意事项

- ⚠️ 离线包文件较大，确保有足够磁盘空间
- ⚠️ 定期更新离线包到最新版本
- ⚠️ 传输离线包时注意文件完整性
- ✅ 可以将离线包复制到 U 盘/移动硬盘
- ✅ 建议压缩后再传输，节省空间和时间

## 🔍 验证离线包

```powershell
# 检查文件完整性
Get-FileHash offline-packages\bettafish-latest.tar -Algorithm SHA256

# 测试加载（不实际导入）
docker load --input offline-packages\bettafish-latest.tar --quiet
```

---

**提示**：如果网络正常，无需使用离线包，部署脚本会自动在线拉取镜像。
