#!/bin/bash

# BettaFish 日志清理脚本
# 用途: 清理旧的部署日志，保留最新的 N 个

# 切换到脚本所在目录
cd "$(dirname "$0")"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 配置
KEEP_COUNT=5  # 保留最新的日志数量
LOG_DIR="logs"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  📋 BettaFish 日志清理工具${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 检查日志目录是否存在
if [ ! -d "$LOG_DIR" ]; then
    echo -e "${YELLOW}⚠️  日志目录不存在: $LOG_DIR${NC}"
    exit 0
fi

# 统计日志文件数量
total_logs=$(ls "$LOG_DIR"/*.log 2>/dev/null | wc -l | tr -d ' ')

if [ "$total_logs" -eq 0 ]; then
    echo -e "${GREEN}✅ 日志目录为空，无需清理${NC}"
    exit 0
fi

echo -e "当前日志文件数: ${YELLOW}$total_logs${NC}"
echo -e "保留最新: ${GREEN}$KEEP_COUNT${NC} 个"
echo ""

# 如果日志数量不超过保留数量，不需要清理
if [ "$total_logs" -le "$KEEP_COUNT" ]; then
    echo -e "${GREEN}✅ 日志数量未超过限制，无需清理${NC}"
    echo ""
    echo "现有日志文件:"
    ls -lht "$LOG_DIR"/*.log 2>/dev/null | head -n "$total_logs"
    exit 0
fi

# 需要删除的日志数量
delete_count=$((total_logs - KEEP_COUNT))

echo -e "${YELLOW}将删除 $delete_count 个旧日志文件${NC}"
echo ""

# 显示即将删除的文件
echo "即将删除的日志:"
ls -t "$LOG_DIR"/*.log | tail -n +$((KEEP_COUNT + 1)) | while read file; do
    size=$(du -h "$file" | cut -f1)
    echo "  - $(basename "$file") ($size)"
done

echo ""
read -p "确认删除？(yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${CYAN}已取消清理操作${NC}"
    exit 0
fi

# 执行删除
echo ""
echo -e "${CYAN}正在清理...${NC}"

deleted=0
ls -t "$LOG_DIR"/*.log | tail -n +$((KEEP_COUNT + 1)) | while read file; do
    rm -f "$file"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} 删除: $(basename "$file")"
        deleted=$((deleted + 1))
    else
        echo -e "${RED}✗${NC} 删除失败: $(basename "$file")"
    fi
done

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ 清理完成！${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 显示剩余的日志
remaining=$(ls "$LOG_DIR"/*.log 2>/dev/null | wc -l | tr -d ' ')
echo "剩余日志文件: $remaining 个"
echo ""
echo "保留的日志:"
ls -lht "$LOG_DIR"/*.log 2>/dev/null | head -n "$KEEP_COUNT"
echo ""
