# 离线安装包目录

## 用途

此目录用于存放 BettaFish 的离线安装资源，适用于无网络或网络受限的环境。

## 离线部署资源

### 1. Docker 镜像
将 Docker 镜像保存为 tar 文件：

```bash
# 导出 BettaFish 镜像
docker save ghcr.nju.edu.cn/666ghj/bettafish:latest -o offline-packages/bettafish-image.tar

# 导出 PostgreSQL 镜像
docker save postgres:15 -o offline-packages/postgres-15-image.tar

# 压缩镜像文件 (可选)
gzip offline-packages/*.tar
```

### 2. Python 依赖包
如果需要本地源码部署，可以下载 Python 包：

```bash
# 下载所有依赖
pip download -r BettaFish-main/requirements.txt -d offline-packages/python-packages/
```

### 3. 系统依赖
根据系统类型，下载必要的系统包：

#### macOS (Homebrew)
```bash
# 下载 Homebrew 包
brew fetch --force --bottle-tag=arm64_monterey docker
```

#### Ubuntu/Debian
```bash
# 下载 deb 包
apt-get download docker-ce docker-ce-cli containerd.io
mv *.deb offline-packages/system-packages/
```

#### CentOS/RHEL
```bash
# 下载 rpm 包
yumdownloader docker-ce docker-ce-cli containerd.io
mv *.rpm offline-packages/system-packages/
```

## 离线安装流程

### 步骤 1: 准备离线包（在有网络的机器上）

```bash
cd /path/to/Linux_macOS

# 创建离线包目录
mkdir -p offline-packages

# 导出 Docker 镜像
docker save ghcr.nju.edu.cn/666ghj/bettafish:latest -o offline-packages/bettafish.tar
docker save postgres:15 -o offline-packages/postgres.tar

# 打包整个部署工具包
cd ..
tar -czf BettaFish-Deployment-Offline.tar.gz Linux_macOS/
```

### 步骤 2: 传输到离线机器

```bash
# 使用 U 盘、移动硬盘或其他方式传输
# BettaFish-Deployment-Offline.tar.gz
```

### 步骤 3: 在离线机器上安装

```bash
# 解压部署包
tar -xzf BettaFish-Deployment-Offline.tar.gz
cd Linux_macOS

# 加载 Docker 镜像
docker load -i offline-packages/bettafish.tar
docker load -i offline-packages/postgres.tar

# 执行部署
./docker-deploy.sh
```

## 离线包文件说明

| 文件名 | 说明 | 大小（约）|
|--------|------|-----------|
| `bettafish.tar` | BettaFish 主镜像 | ~2-3 GB |
| `postgres.tar` | PostgreSQL 数据库镜像 | ~150 MB |
| `python-packages/` | Python 依赖包 | ~500 MB |
| `system-packages/` | 系统依赖包 | 变动 |

## 网络限制解决方案

### 方案 1: 使用国内镜像源

编辑 `BettaFish-main/docker-compose.yml`：

```yaml
services:
  bettafish:
    image: ghcr.nju.edu.cn/666ghj/bettafish:latest  # 南京大学镜像
```

### 方案 2: 配置 Docker 镜像加速

编辑 `/etc/docker/daemon.json`：

```json
{
  "registry-mirrors": [
    "https://docker.nju.edu.cn",
    "https://docker.mirrors.ustc.edu.cn"
  ]
}
```

### 方案 3: 使用代理

```bash
export HTTP_PROXY=http://proxy.example.com:8080
export HTTPS_PROXY=http://proxy.example.com:8080
./docker-deploy.sh
```

## 注意事项

- 📦 离线镜像文件较大，请确保有足够的存储空间
- 🔄 定期更新离线包，保持版本同步
- ✅ 在导出镜像前，先拉取最新版本
- 🗜️ 可以使用 `gzip` 压缩 tar 文件减小体积

## 快速离线包制作脚本

```bash
#!/bin/bash
# 创建完整离线部署包

echo "正在创建离线部署包..."

# 导出镜像
docker save ghcr.nju.edu.cn/666ghj/bettafish:latest | gzip > offline-packages/bettafish.tar.gz
docker save postgres:15 | gzip > offline-packages/postgres.tar.gz

# 打包部署工具
cd ..
tar -czf BettaFish-Offline-$(date +%Y%m%d).tar.gz Linux_macOS/

echo "离线包创建完成: BettaFish-Offline-$(date +%Y%m%d).tar.gz"
```

## 验证离线包

```bash
# 解压并验证
tar -tzf BettaFish-Offline-20241116.tar.gz | head -20

# 检查镜像文件
docker load < offline-packages/bettafish.tar.gz --quiet && echo "✓ 镜像文件有效"
```
