#!/bin/bash
# 创建最小核心部署包
# 用途: 打包 7 个核心文件用于分发
# 使用: ./create-minimal-package.sh

set -e

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📦 创建 BettaFish 最小核心部署包${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="BettaFish-Deployment-Kit-Minimal"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="BettaFish-Minimal-${TIMESTAMP}.tar.gz"

# 检查源文件
echo -e "${BLUE}▶ 步骤 1: 检查源文件${NC}"
echo ""

REQUIRED_FILES=(
    "docker-deploy.sh"
    "README.md"
    "最新文档/终极部署指南.md"
    "最新文档/部署流程可视化_v2.1.html"
    "BettaFish-main"
)

MISSING_FILES=()

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -e "$SCRIPT_DIR/$file" ]; then
        MISSING_FILES+=("$file")
        echo -e "${YELLOW}⚠️  缺失: $file${NC}"
    else
        echo -e "${GREEN}✓${NC} $file"
    fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}警告: 缺少 ${#MISSING_FILES[@]} 个文件${NC}"
    echo "缺失的文件:"
    for file in "${MISSING_FILES[@]}"; do
        echo "  - $file"
    done
    echo ""
    read -p "是否继续? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "已取消"
        exit 1
    fi
fi

# 清理旧目录
echo ""
echo -e "${BLUE}▶ 步骤 2: 准备目标目录${NC}"
echo ""

if [ -d "/tmp/$TARGET_DIR" ]; then
    echo "清理旧目录..."
    rm -rf "/tmp/$TARGET_DIR"
fi

mkdir -p "/tmp/$TARGET_DIR/最新文档"
echo -e "${GREEN}✓${NC} 目录已创建: /tmp/$TARGET_DIR"

# 复制文件
echo ""
echo -e "${BLUE}▶ 步骤 3: 复制核心文件${NC}"
echo ""

copy_file() {
    local src="$1"
    local dst="$2"
    if [ -e "$SCRIPT_DIR/$src" ]; then
        cp -r "$SCRIPT_DIR/$src" "/tmp/$TARGET_DIR/$dst"
        local size=$(du -h "$SCRIPT_DIR/$src" | cut -f1)
        echo -e "${GREEN}✓${NC} $src ($size)"
    else
        echo -e "${YELLOW}⚠${NC} 跳过: $src (不存在)"
    fi
}

copy_file "docker-deploy.sh" "./docker-deploy.sh"
copy_file "README.md" "./README.md"
copy_file "最新文档/终极部署指南.md" "./最新文档/终极部署指南.md"
copy_file "最新文档/部署流程可视化_v2.1.html" "./最新文档/部署流程可视化_v2.1.html"
copy_file "BettaFish-main" "./BettaFish-main"

# 添加说明文件
echo ""
echo -e "${BLUE}▶ 步骤 4: 创建说明文件${NC}"
echo ""

cat > "/tmp/$TARGET_DIR/最新文档/最小包说明.md" << 'EOF'
# BettaFish 最小核心包说明

## 包含文件

本最小包仅包含部署所需的 7 个核心文件：

1. **docker-deploy.sh** - 自动化部署脚本
2. **README.md** - 项目说明
3. **最新文档/终极部署指南.md** - 详细部署指南
4. **最新文档/部署流程可视化_v2.1.html** - 可视化流程图
5. **BettaFish-main/** - 官方项目源码
   - docker-compose.yml - Docker 配置
   - .env.example - 环境变量模板

## 快速开始

```bash
# 1. 解压
tar -xzf BettaFish-Minimal-*.tar.gz
cd BettaFish-Deployment-Kit-Minimal

# 2. 执行部署脚本
./docker-deploy.sh

# 3. 访问
# http://localhost:8501
```

## 总耗时

5-8 分钟（取决于网络速度）

## 缺少的内容

最小包不包含以下内容（不影响部署）：
- 旧版文档
- 开发说明
- 离线部署工具
- 其他辅助脚本

如需完整包，请下载：
https://github.com/USER/REPO/releases

## 支持

- 官方仓库: https://github.com/666ghj/BettaFish
- 问题反馈: https://github.com/666ghj/BettaFish/issues
EOF

echo -e "${GREEN}✓${NC} 最小包说明.md"

# 设置权限
echo ""
echo -e "${BLUE}▶ 步骤 5: 设置权限${NC}"
echo ""

chmod +x "/tmp/$TARGET_DIR/docker-deploy.sh"
echo -e "${GREEN}✓${NC} docker-deploy.sh (可执行)"

# 打包
echo ""
echo -e "${BLUE}▶ 步骤 6: 打包文件${NC}"
echo ""

cd /tmp
echo "压缩中..."

if tar -czf "$OUTPUT_FILE" "$TARGET_DIR"; then
    PACKAGE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo -e "${GREEN}✓${NC} 打包完成"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${GREEN}🎉 最小核心包创建成功！${NC}"
    echo ""
    echo "📦 包信息:"
    echo "  文件: /tmp/$OUTPUT_FILE"
    echo "  大小: $PACKAGE_SIZE"
    echo ""
    echo "📁 内容预览:"
    tar -tzf "$OUTPUT_FILE" | head -20
    echo "  ..."
    echo ""
    echo "✅ 下一步:"
    echo "  1. 测试: cd /tmp && tar -xzf $OUTPUT_FILE && cd $TARGET_DIR && ./docker-deploy.sh"
    echo "  2. 移动: mv /tmp/$OUTPUT_FILE $SCRIPT_DIR/"
    echo "  3. 上传: gh release upload v1.0 $SCRIPT_DIR/$OUTPUT_FILE"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
else
    echo -e "${YELLOW}❌ 打包失败${NC}"
    exit 1
fi

# 询问是否移动到当前目录
echo ""
read -p "是否将包移动到当前目录? [Y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    mv "/tmp/$OUTPUT_FILE" "$SCRIPT_DIR/"
    echo -e "${GREEN}✓${NC} 已移动到: $SCRIPT_DIR/$OUTPUT_FILE"
fi

# 询问是否清理临时目录
echo ""
read -p "是否清理临时目录? [Y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    rm -rf "/tmp/$TARGET_DIR"
    echo -e "${GREEN}✓${NC} 临时目录已清理"
fi

echo ""
echo -e "${GREEN}完成！${NC}"
