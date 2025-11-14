#!/bin/bash

# ================================================================
# Docker 构建缓存和镜像清理脚本
# ================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# 日志函数
log_info() {
    echo -e "${BLUE}ℹ️  ${NC}$1"
}

log_success() {
    echo -e "${GREEN}✅ ${NC}$1"
}

log_warn() {
    echo -e "${YELLOW}⚠️  ${NC}$1"
}

log_error() {
    echo -e "${RED}❌ ${NC}$1"
}

# Logo
cat << "EOF"

  ____             _                ____ _
 |  _ \  ___   ___| | _____ _ __   / ___| | ___  __ _ _ __  _   _ _ __
 | | | |/ _ \ / __| |/ / _ \ '__| | |   | |/ _ \/ _` | '_ \| | | | '_ \
 | |_| | (_) | (__|   <  __/ |    | |___| |  __/ (_| | | | | |_| | |_) |
 |____/ \___/ \___|_|\_\___|_|     \____|_|\___|\__,_|_| |_|\__,_| .__/
                                                                  |_|

       🐟 BettaFish Docker 清理工具
        Powered by LIONCC.AI - 2025

EOF

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 获取当前磁盘使用情况
get_docker_disk_usage() {
    echo -e "${CYAN}当前 Docker 磁盘使用情况:${NC}"
    echo ""
    docker system df
    echo ""
}

# 显示清理选项
show_cleanup_options() {
    echo -e "${CYAN}请选择清理选项:${NC}"
    echo ""
    echo "  ${YELLOW}1.${NC} 清理构建缓存 (Build Cache)"
    echo "     • 删除所有未使用的构建缓存"
    echo "     • 不影响现有镜像"
    echo "     • ${GREEN}推荐${NC}: 定期清理"
    echo ""
    echo "  ${YELLOW}2.${NC} 清理悬空镜像 (Dangling Images)"
    echo "     • 删除未标记的中间镜像"
    echo "     • 不影响正在使用的镜像"
    echo "     • ${GREEN}安全${NC}: 可放心清理"
    echo ""
    echo "  ${YELLOW}3.${NC} 清理未使用的镜像 (Unused Images)"
    echo "     • 删除所有未被容器使用的镜像"
    echo "     • ${YELLOW}警告${NC}: 可能删除 BettaFish 镜像"
    echo ""
    echo "  ${YELLOW}4.${NC} 全面清理 (Deep Clean)"
    echo "     • 清理所有未使用的资源"
    echo "     • 包括: 镜像、容器、网络、卷"
    echo "     • ${RED}危险${NC}: 慎重选择"
    echo ""
    echo "  ${YELLOW}5.${NC} 仅显示统计信息"
    echo "     • 不执行任何清理操作"
    echo "     • 查看可清理的空间"
    echo ""
    echo "  ${YELLOW}0.${NC} 退出"
    echo ""
}

# 清理构建缓存
cleanup_build_cache() {
    log_info "准备清理构建缓存..."
    echo ""

    printf "${YELLOW}确认清理? [y/N]: ${NC}"
    read CONFIRM
    CONFIRM=$(echo "$CONFIRM" | tr '[:upper:]' '[:lower:]')

    if [[ "$CONFIRM" == "y" ]]; then
        echo ""
        log_info "清理中..."

        RESULT=$(docker builder prune -f 2>&1)

        echo ""
        log_success "构建缓存已清理"

        # 提取释放的空间
        if echo "$RESULT" | grep -q "Total reclaimed space"; then
            RECLAIMED=$(echo "$RESULT" | grep "Total reclaimed space" | awk '{print $4 " " $5}')
            echo -e "  ${CYAN}释放空间:${NC} $RECLAIMED"
        fi
    else
        log_info "取消清理"
    fi
    echo ""
}

# 清理悬空镜像
cleanup_dangling_images() {
    log_info "准备清理悬空镜像..."
    echo ""

    # 显示悬空镜像列表
    DANGLING_COUNT=$(docker images -f "dangling=true" -q | wc -l | tr -d ' ')

    if [ "$DANGLING_COUNT" -eq 0 ]; then
        log_success "没有悬空镜像需要清理"
        echo ""
        return
    fi

    echo -e "${YELLOW}发现 $DANGLING_COUNT 个悬空镜像${NC}"
    echo ""

    printf "${YELLOW}确认清理? [y/N]: ${NC}"
    read CONFIRM
    CONFIRM=$(echo "$CONFIRM" | tr '[:upper:]' '[:lower:]')

    if [[ "$CONFIRM" == "y" ]]; then
        echo ""
        log_info "清理中..."

        docker image prune -f > /dev/null 2>&1

        echo ""
        log_success "悬空镜像已清理"
        echo -e "  ${CYAN}清理数量:${NC} $DANGLING_COUNT 个"
    else
        log_info "取消清理"
    fi
    echo ""
}

# 清理未使用的镜像
cleanup_unused_images() {
    log_warn "此操作将删除所有未被容器使用的镜像"
    log_warn "可能包括 BettaFish 镜像!"
    echo ""

    # 显示将被删除的镜像
    echo -e "${CYAN}将被删除的镜像:${NC}"
    echo ""
    docker images --filter "dangling=false" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    echo ""

    printf "${RED}确认清理? (请输入 yes 确认): ${NC}"
    read CONFIRM
    CONFIRM=$(echo "$CONFIRM" | tr '[:upper:]' '[:lower:]')

    if [[ "$CONFIRM" == "yes" ]]; then
        echo ""
        log_info "清理中..."

        RESULT=$(docker image prune -a -f 2>&1)

        echo ""
        log_success "未使用镜像已清理"

        # 提取释放的空间
        if echo "$RESULT" | grep -q "Total reclaimed space"; then
            RECLAIMED=$(echo "$RESULT" | grep "Total reclaimed space" | awk '{print $4 " " $5}')
            echo -e "  ${CYAN}释放空间:${NC} $RECLAIMED"
        fi
    else
        log_info "取消清理"
    fi
    echo ""
}

# 全面清理
deep_clean() {
    log_warn "全面清理将删除:"
    echo "  • 所有停止的容器"
    echo "  • 所有未使用的镜像"
    echo "  • 所有未使用的网络"
    echo "  • 所有未使用的卷"
    echo "  • 所有构建缓存"
    echo ""
    log_warn "这是一个危险操作!"
    echo ""

    printf "${RED}确认全面清理? (请输入 CLEAN 确认): ${NC}"
    read CONFIRM

    if [[ "$CONFIRM" == "CLEAN" ]]; then
        echo ""
        log_info "执行全面清理..."
        echo ""

        RESULT=$(docker system prune -a --volumes -f 2>&1)

        echo ""
        log_success "全面清理完成"

        # 提取释放的空间
        if echo "$RESULT" | grep -q "Total reclaimed space"; then
            RECLAIMED=$(echo "$RESULT" | grep "Total reclaimed space" | awk '{print $4 " " $5}')
            echo -e "  ${CYAN}释放空间:${NC} $RECLAIMED"
        fi
    else
        log_info "取消清理"
    fi
    echo ""
}

# 显示统计信息
show_stats() {
    log_info "Docker 磁盘使用详情"
    echo ""

    # 显示系统统计
    docker system df -v
    echo ""

    # 显示构建缓存大小
    BUILD_CACHE_SIZE=$(docker system df | grep "Build Cache" | awk '{print $4}')
    log_info "构建缓存: $BUILD_CACHE_SIZE"

    # 显示悬空镜像数量
    DANGLING_COUNT=$(docker images -f "dangling=true" -q | wc -l | tr -d ' ')
    log_info "悬空镜像: $DANGLING_COUNT 个"

    # 显示可回收空间
    RECLAIMABLE=$(docker system df | grep "Build Cache" | awk '{print $NF}')
    log_info "可回收空间: $RECLAIMABLE"
    echo ""
}

# 主菜单循环
main_menu() {
    while true; do
        get_docker_disk_usage
        show_cleanup_options

        printf "${CYAN}请选择 [0-5]: ${NC}"
        read CHOICE
        echo ""

        case $CHOICE in
            1)
                cleanup_build_cache
                ;;
            2)
                cleanup_dangling_images
                ;;
            3)
                cleanup_unused_images
                ;;
            4)
                deep_clean
                ;;
            5)
                show_stats
                ;;
            0)
                log_info "退出清理工具"
                echo ""
                exit 0
                ;;
            *)
                log_error "无效选项，请重新选择"
                echo ""
                ;;
        esac
    done
}

# 检查 Docker 是否运行
if ! docker info > /dev/null 2>&1; then
    log_error "Docker 未运行或无权限访问"
    echo ""
    log_info "请检查:"
    echo "  1. Docker Desktop 是否已启动"
    echo "  2. 是否有 Docker 访问权限"
    echo ""
    exit 1
fi

# 启动主菜单
main_menu
