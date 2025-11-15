#!/bin/bash
# BettaFish 部署工具包路径验证脚本
# 用途: 验证所有文件和目录结构是否符合脚本依赖要求

# 智能获取脚本所在目录
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$BASE_DIR" || exit 1

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}=========================================${NC}"
echo -e "${CYAN}  BettaFish 部署工具包路径验证${NC}"
echo -e "${CYAN}=========================================${NC}"
echo ""
echo -e "基础路径: ${YELLOW}$BASE_DIR${NC}"
echo ""

# 计数器
PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

# ==========================================
# 1. 检查必需的脚本文件
# ==========================================
echo -e "${CYAN}[1] 检查必需的脚本文件${NC}"
echo ""

REQUIRED_SCRIPTS=(
    "docker-deploy.sh"
    "menu.sh"
    "diagnose.sh"
    "docker-cleanup.sh"
    "log-cleanup.sh"
)

for file in "${REQUIRED_SCRIPTS[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  ${GREEN}✅${NC} $file"
        ((PASS_COUNT++))
    else
        echo -e "  ${RED}❌${NC} $file (缺失)"
        ((FAIL_COUNT++))
    fi
done
echo ""

# ==========================================
# 2. 检查文档目录
# ==========================================
echo -e "${CYAN}[2] 检查文档目录和文件${NC}"
echo ""

if [ -d "docs" ]; then
    echo -e "  ${GREEN}✅${NC} docs/ 目录存在"
    ((PASS_COUNT++))

    DOC_FILES=(
        "README.md"
        "用户完整指南.html"
        "用户使用手册.md"
        "快速参考卡片.md"
        "文件夹结构说明.html"
    )

    for file in "${DOC_FILES[@]}"; do
        if [ -f "docs/$file" ]; then
            echo -e "    ${GREEN}✅${NC} $file"
            ((PASS_COUNT++))
        else
            echo -e "    ${YELLOW}⚠️${NC}  $file (缺失)"
            ((WARN_COUNT++))
        fi
    done
else
    echo -e "  ${RED}❌${NC} docs/ 目录不存在"
    ((FAIL_COUNT++))
fi
echo ""

# ==========================================
# 3. 检查旧的 Guides 目录
# ==========================================
echo -e "${CYAN}[3] 检查旧的 Guides/ 目录${NC}"
echo ""

if [ -d "Guides" ]; then
    echo -e "  ${YELLOW}⚠️${NC}  Guides/ 仍然存在"
    echo -e "     ${YELLOW}建议:${NC} 将内容移至 docs/ 后删除"
    echo -e "     ${YELLOW}命令:${NC} mv Guides/* docs/ && rmdir Guides"
    ((WARN_COUNT++))
else
    echo -e "  ${GREEN}✅${NC} Guides/ 已移除 (正确)"
    ((PASS_COUNT++))
fi
echo ""

# ==========================================
# 4. 检查必需的目录
# ==========================================
echo -e "${CYAN}[4] 检查必需的目录${NC}"
echo ""

REQUIRED_DIRS=(
    "docs"
    "logs"
    "backups"
    "offline-packages"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo -e "  ${GREEN}✅${NC} $dir/"
        ((PASS_COUNT++))
    else
        echo -e "  ${YELLOW}⚠️${NC}  $dir/ (不存在，运行时会自动创建)"
        ((WARN_COUNT++))
    fi
done
echo ""

# ==========================================
# 5. 检查脚本可执行权限
# ==========================================
echo -e "${CYAN}[5] 检查脚本可执行权限${NC}"
echo ""

SCRIPTS=(
    "docker-deploy.sh"
    "menu.sh"
    "diagnose.sh"
    "docker-cleanup.sh"
    "log-cleanup.sh"
)

for file in "${SCRIPTS[@]}"; do
    if [ -f "$file" ]; then
        if [ -x "$file" ]; then
            echo -e "  ${GREEN}✅${NC} $file 可执行"
            ((PASS_COUNT++))
        else
            echo -e "  ${YELLOW}⚠️${NC}  $file 不可执行"
            echo -e "     ${YELLOW}建议:${NC} chmod +x $file"
            ((WARN_COUNT++))
        fi
    fi
done
echo ""

# ==========================================
# 6. 检查 README 文件
# ==========================================
echo -e "${CYAN}[6] 检查 README 文件${NC}"
echo ""

README_FILES=(
    "README.md"
    "START.txt"
    "backups/README.md"
    "offline-packages/README.md"
)

for file in "${README_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  ${GREEN}✅${NC} $file"
        ((PASS_COUNT++))
    else
        echo -e "  ${YELLOW}⚠️${NC}  $file (缺失)"
        ((WARN_COUNT++))
    fi
done
echo ""

# ==========================================
# 7. 检查 BettaFish-main 目录
# ==========================================
echo -e "${CYAN}[7] 检查 BettaFish-main 目录${NC}"
echo ""

if [ -d "BettaFish-main" ]; then
    echo -e "  ${GREEN}✅${NC} BettaFish-main/ 存在"

    if [ -f "BettaFish-main/docker-compose.yml" ]; then
        echo -e "    ${GREEN}✅${NC} docker-compose.yml 存在"
        ((PASS_COUNT++))
    else
        echo -e "    ${YELLOW}⚠️${NC}  docker-compose.yml 不存在"
        ((WARN_COUNT++))
    fi

    if [ -f "BettaFish-main/.env" ]; then
        echo -e "    ${GREEN}✅${NC} .env 存在"
        ((PASS_COUNT++))
    else
        echo -e "    ${YELLOW}⚠️${NC}  .env 不存在 (部署后生成)"
        ((WARN_COUNT++))
    fi
else
    echo -e "  ${YELLOW}⚠️${NC}  BettaFish-main/ 不存在 (部署后生成)"
    ((WARN_COUNT++))
fi
echo ""

# ==========================================
# 总结
# ==========================================
echo -e "${CYAN}=========================================${NC}"
echo -e "${CYAN}  验证结果总结${NC}"
echo -e "${CYAN}=========================================${NC}"
echo ""
echo -e "  ${GREEN}通过:${NC} $PASS_COUNT 项"
echo -e "  ${YELLOW}警告:${NC} $WARN_COUNT 项"
echo -e "  ${RED}失败:${NC} $FAIL_COUNT 项"
echo ""

# ==========================================
# 建议操作
# ==========================================
if [ $WARN_COUNT -gt 0 ] || [ $FAIL_COUNT -gt 0 ]; then
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${CYAN}  建议操作${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo ""

    # 检查是否需要设置权限
    NEED_CHMOD=false
    for file in *.sh; do
        if [ -f "$file" ] && [ ! -x "$file" ]; then
            NEED_CHMOD=true
            break
        fi
    done

    if [ "$NEED_CHMOD" = true ]; then
        echo -e "${YELLOW}1. 设置脚本可执行权限:${NC}"
        echo -e "   chmod +x *.sh"
        echo ""
    fi

    if [ -d "Guides" ]; then
        echo -e "${YELLOW}2. 移除旧的 Guides/ 目录:${NC}"
        echo -e "   # 如果 docs/ 已有内容，检查差异"
        echo -e "   diff -r Guides/ docs/"
        echo -e "   # 如果一致，删除 Guides/"
        echo -e "   rm -rf Guides/"
        echo ""
    fi

    if [ ! -d "BettaFish-main" ]; then
        echo -e "${YELLOW}3. 首次部署运行:${NC}"
        echo -e "   ./docker-deploy.sh"
        echo ""
    fi
fi

# ==========================================
# 快速修复命令
# ==========================================
if [ $WARN_COUNT -gt 0 ] || [ $FAIL_COUNT -gt 0 ]; then
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${CYAN}  快速修复命令${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo ""
    echo -e "# 一键修复所有权限问题"
    echo -e "chmod +x *.sh"
    echo ""
    echo -e "# 创建缺失的空目录"
    echo -e "mkdir -p logs backups offline-packages"
    echo ""
    echo -e "# 添加 .gitkeep 文件"
    echo -e "touch logs/.gitkeep backups/.gitkeep offline-packages/.gitkeep"
    echo ""
fi

# ==========================================
# 退出状态
# ==========================================
echo -e "${CYAN}=========================================${NC}"
if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}✅ 验证通过！可以正常使用部署工具包${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}❌ 验证失败！请修复上述问题后重试${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo ""
    exit 1
fi
