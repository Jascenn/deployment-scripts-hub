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

log_step() {
    echo -e "\n${CYAN}${BOLD}▶ $1${NC}\n"
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
    echo -e "  ${YELLOW}1.${NC} 清理构建缓存 (Build Cache)"
    echo "     • 删除所有未使用的构建缓存"
    echo "     • 不影响现有镜像"
    echo -e "     • ${GREEN}推荐${NC}: 定期清理"
    echo ""
    echo -e "  ${YELLOW}2.${NC} 清理悬空镜像 (Dangling Images)"
    echo "     • 删除未标记的中间镜像"
    echo "     • 不影响正在使用的镜像"
    echo -e "     • ${GREEN}安全${NC}: 可放心清理"
    echo ""
    echo -e "  ${YELLOW}3.${NC} 清理未使用的镜像 (Unused Images)"
    echo "     • 删除所有未被容器使用的镜像"
    echo -e "     • ${YELLOW}警告${NC}: 可能删除 BettaFish 镜像"
    echo ""
    echo -e "  ${YELLOW}4.${NC} 全面清理 (Deep Clean)"
    echo "     • 清理所有未使用的资源"
    echo "     • 包括: 镜像、容器、网络、卷"
    echo -e "     • ${RED}危险${NC}: 慎重选择"
    echo ""
    echo -e "  ${YELLOW}5.${NC} 仅显示统计信息"
    echo "     • 不执行任何清理操作"
    echo "     • 查看可清理的空间"
    echo ""
    echo -e "  ${YELLOW}6.${NC} 查看安装历史 ${CYAN}⭐${NC}"
    echo "     • 显示组件安装记录"
    echo "     • 查看哪些是脚本安装的"
    echo ""
    echo -e "  ${YELLOW}7.${NC} 智能卸载 BettaFish ${RED}⚠️${NC}"
    echo "     • 只卸载脚本安装的组件"
    echo "     • 保留已有的系统工具"
    echo "     • 恢复到安装前状态"
    echo ""
    echo -e "  ${YELLOW}8.${NC} 停止服务并清理镜像 ${RED}⚠️${NC}"
    echo "     • 停止所有运行中的 BettaFish 容器"
    echo "     • 删除 BettaFish 相关镜像"
    echo "     • 释放约 10GB 空间"
    echo -e "     • ${YELLOW}注意${NC}: 下次部署需重新下载镜像"
    echo ""
    echo -e "  ${YELLOW}0.${NC} 退出"
    echo ""
}

# 清理构建缓存
cleanup_build_cache() {
    log_step "检查构建缓存状态"

    # 获取构建缓存信息
    BUILD_CACHE_INFO=$(docker system df --format "table {{.Type}}\t{{.TotalCount}}\t{{.Active}}\t{{.Size}}\t{{.Reclaimable}}" | grep "Build Cache" || echo "")

    if [ -n "$BUILD_CACHE_INFO" ]; then
        CACHE_SIZE=$(echo "$BUILD_CACHE_INFO" | awk '{print $4}')
        CACHE_RECLAIMABLE=$(echo "$BUILD_CACHE_INFO" | awk '{print $5}')

        echo -e "${CYAN}当前构建缓存状态:${NC}"
        echo ""
        echo -e "  总大小: ${YELLOW}${CACHE_SIZE}${NC}"
        echo -e "  可清理: ${GREEN}${CACHE_RECLAIMABLE}${NC}"
        echo ""

        if [ "$CACHE_SIZE" = "0B" ]; then
            log_success "没有构建缓存需要清理"
            echo ""
            printf "${CYAN}按回车键继续...${NC}"
            read
            echo ""
            return
        fi

        echo -e "${YELLOW}⚠️  即将清理的内容:${NC}"
        echo "  • 所有未使用的构建缓存"
        echo "  • Docker 层缓存"
        echo "  • 构建历史记录"
        echo ""
        echo -e "${GREEN}✓ 影响:${NC}"
        echo "  • 不会影响现有镜像"
        echo "  • 不会影响运行中的容器"
        echo "  • 下次构建可能会稍慢（需重建缓存）"
        echo ""
    fi

    printf "${YELLOW}确认清理构建缓存? [y/N]: ${NC}"
    read CONFIRM
    CONFIRM=$(echo "$CONFIRM" | tr '[:upper:]' '[:lower:]')

    if [[ "$CONFIRM" == "y" ]]; then
        echo ""
        log_info "正在清理构建缓存..."

        RESULT=$(docker builder prune -af 2>&1)

        echo ""
        log_success "构建缓存清理完成！"

        # 提取释放的空间
        if echo "$RESULT" | grep -q "Total reclaimed space"; then
            RECLAIMED=$(echo "$RESULT" | grep "Total reclaimed space" | awk '{print $4 " " $5}')
            echo -e "  ${GREEN}✓ 释放空间:${NC} ${BOLD}$RECLAIMED${NC}"
        fi
    else
        log_info "已取消清理"
    fi

    echo ""
    printf "${CYAN}按回车键继续...${NC}"
    read
    echo ""
}

# 清理悬空镜像
cleanup_dangling_images() {
    log_step "检查悬空镜像"

    # 获取悬空镜像列表
    DANGLING_IMAGES=$(docker images -f "dangling=true" --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}")
    DANGLING_COUNT=$(docker images -f "dangling=true" -q | wc -l | tr -d ' ')

    if [ "$DANGLING_COUNT" -eq 0 ]; then
        log_success "没有悬空镜像需要清理"
        echo ""
        printf "${CYAN}按回车键继续...${NC}"
        read
        echo ""
        return
    fi

    # 计算悬空镜像总大小
    TOTAL_SIZE=$(docker images -f "dangling=true" --format "{{.Size}}" | awk '{
        if (index($0, "GB")) {
            gsub("GB", "", $0); sum += $0 * 1024
        } else if (index($0, "MB")) {
            gsub("MB", "", $0); sum += $0
        } else if (index($0, "KB")) {
            gsub("KB", "", $0); sum += $0 / 1024
        }
    } END {
        if (sum > 1024) printf "%.1fGB", sum/1024
        else printf "%.0fMB", sum
    }')

    echo -e "${CYAN}当前悬空镜像状态:${NC}"
    echo ""
    echo -e "  发现镜像: ${YELLOW}${DANGLING_COUNT} 个${NC}"
    echo -e "  占用空间: ${YELLOW}约 ${TOTAL_SIZE}${NC}"
    echo ""

    echo -e "${CYAN}悬空镜像列表:${NC}"
    echo "$DANGLING_IMAGES" | head -20
    if [ "$DANGLING_COUNT" -gt 20 ]; then
        echo "  ... 还有 $((DANGLING_COUNT - 20)) 个镜像"
    fi
    echo ""

    echo -e "${YELLOW}⚠️  什么是悬空镜像:${NC}"
    echo "  • 没有标签的中间层镜像"
    echo "  • 构建过程产生的临时镜像"
    echo "  • 被新版本替换的旧镜像"
    echo ""
    echo -e "${GREEN}✓ 清理后影响:${NC}"
    echo "  • 不会影响正在使用的镜像"
    echo "  • 不会影响有标签的镜像"
    echo "  • 释放磁盘空间"
    echo ""

    printf "${YELLOW}确认清理所有悬空镜像? [y/N]: ${NC}"
    read CONFIRM
    CONFIRM=$(echo "$CONFIRM" | tr '[:upper:]' '[:lower:]')

    if [[ "$CONFIRM" == "y" ]]; then
        echo ""
        log_info "正在清理悬空镜像..."

        docker image prune -f > /dev/null 2>&1

        echo ""
        log_success "悬空镜像清理完成！"
        echo -e "  ${GREEN}✓ 清理数量:${NC} ${BOLD}$DANGLING_COUNT 个${NC}"
        echo -e "  ${GREEN}✓ 释放空间:${NC} ${BOLD}约 ${TOTAL_SIZE}${NC}"
    else
        log_info "已取消清理"
    fi

    echo ""
    printf "${CYAN}按回车键继续...${NC}"
    read
    echo ""
}

# 清理未使用的镜像
cleanup_unused_images() {
    log_step "检查未使用的镜像"

    # 获取所有镜像
    ALL_IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}")
    ALL_COUNT=$(echo "$ALL_IMAGES" | wc -l | tr -d ' ')

    # 获取正在使用的镜像
    USED_IMAGES=$(docker ps -a --format "{{.Image}}" | sort | uniq)
    USED_COUNT=$(echo "$USED_IMAGES" | wc -l | tr -d ' ')

    # 计算未使用的镜像
    UNUSED_COUNT=$((ALL_COUNT - USED_COUNT))

    if [ "$UNUSED_COUNT" -le 0 ]; then
        log_success "所有镜像都在使用中，无需清理"
        echo ""
        printf "${CYAN}按回车键继续...${NC}"
        read
        echo ""
        return
    fi

    echo -e "${CYAN}当前镜像使用状态:${NC}"
    echo ""
    echo -e "  总镜像数: ${YELLOW}${ALL_COUNT} 个${NC}"
    echo -e "  使用中的: ${GREEN}${USED_COUNT} 个${NC}"
    echo -e "  未使用的: ${RED}${UNUSED_COUNT} 个${NC}"
    echo ""

    # 显示将被删除的镜像（最多显示10个）
    echo -e "${CYAN}将被删除的镜像示例:${NC}"
    docker images --filter "dangling=false" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | head -11
    if [ "$UNUSED_COUNT" -gt 10 ]; then
        echo "  ... 还有更多镜像"
    fi
    echo ""

    echo -e "${RED}⚠️  警告:${NC}"
    echo "  • 将删除所有未被容器使用的镜像"
    echo "  • 可能包括 BettaFish 镜像"
    echo "  • 可能包括其他项目的镜像"
    echo ""
    echo -e "${YELLOW}💡 建议:${NC}"
    echo "  • 先运行 'docker ps -a' 查看所有容器"
    echo "  • 确认重要镜像有容器引用"
    echo ""

    printf "${RED}确认清理所有未使用的镜像? (请输入 yes 确认): ${NC}"
    read CONFIRM
    CONFIRM=$(echo "$CONFIRM" | tr '[:upper:]' '[:lower:]')

    if [[ "$CONFIRM" == "yes" ]]; then
        echo ""
        log_info "正在清理未使用的镜像..."

        RESULT=$(docker image prune -a -f 2>&1)

        echo ""
        log_success "未使用镜像清理完成！"

        # 提取释放的空间
        if echo "$RESULT" | grep -q "Total reclaimed space"; then
            RECLAIMED=$(echo "$RESULT" | grep "Total reclaimed space" | awk '{print $4 " " $5}')
            echo -e "  ${GREEN}✓ 释放空间:${NC} ${BOLD}$RECLAIMED${NC}"
        fi
    else
        log_info "已取消清理"
    fi

    echo ""
    printf "${CYAN}按回车键继续...${NC}"
    read
    echo ""
}

# 全面清理
deep_clean() {
    log_step "全面清理 - 深度分析"

    echo -e "${CYAN}正在分析 Docker 资源使用情况...${NC}"
    echo ""

    # 获取当前资源统计
    CONTAINERS_TOTAL=$(docker ps -a -q | wc -l | tr -d ' ')
    CONTAINERS_RUNNING=$(docker ps -q | wc -l | tr -d ' ')
    CONTAINERS_STOPPED=$((CONTAINERS_TOTAL - CONTAINERS_RUNNING))

    IMAGES_TOTAL=$(docker images -q | wc -l | tr -d ' ')
    VOLUMES_TOTAL=$(docker volume ls -q | wc -l | tr -d ' ')
    NETWORKS_TOTAL=$(docker network ls -q | wc -l | tr -d ' ')

    echo -e "${CYAN}当前 Docker 资源状态:${NC}"
    echo ""
    echo -e "  ${YELLOW}容器:${NC}"
    echo -e "    • 总数: ${BOLD}$CONTAINERS_TOTAL${NC}"
    echo -e "    • 运行中: ${GREEN}$CONTAINERS_RUNNING${NC}"
    echo -e "    • 已停止: ${RED}$CONTAINERS_STOPPED${NC}"
    echo ""
    echo -e "  ${YELLOW}镜像:${NC} ${BOLD}$IMAGES_TOTAL 个${NC}"
    echo -e "  ${YELLOW}卷:${NC} ${BOLD}$VOLUMES_TOTAL 个${NC}"
    echo -e "  ${YELLOW}网络:${NC} ${BOLD}$NETWORKS_TOTAL 个${NC}"
    echo ""

    # 显示磁盘使用情况
    echo -e "${CYAN}磁盘使用情况:${NC}"
    docker system df
    echo ""

    echo -e "${RED}⚠️  全面清理将删除:${NC}"
    echo "  • 所有停止的容器 ($CONTAINERS_STOPPED 个)"
    echo "  • 所有未使用的镜像"
    echo "  • 所有未使用的网络"
    echo "  • 所有未使用的卷"
    echo "  • 所有构建缓存"
    echo ""
    echo -e "${YELLOW}⚠️  注意事项:${NC}"
    echo "  • 这是最激进的清理方式"
    echo "  • 可能删除 BettaFish 相关资源"
    echo "  • 删除后需要重新下载镜像"
    echo "  • 不可恢复，请谨慎操作"
    echo ""
    log_warn "这是一个危险操作!"
    echo ""

    printf "${RED}确认全面清理? (请输入 CLEAN 确认): ${NC}"
    read CONFIRM

    if [[ "$CONFIRM" == "CLEAN" ]]; then
        echo ""
        log_info "开始执行全面清理..."
        echo ""

        # 分步执行清理，显示进度
        echo -e "${CYAN}[1/5] 清理停止的容器...${NC}"
        docker container prune -f > /dev/null 2>&1
        echo -e "${GREEN}  ✓ 完成${NC}"

        echo -e "${CYAN}[2/5] 清理未使用的网络...${NC}"
        docker network prune -f > /dev/null 2>&1
        echo -e "${GREEN}  ✓ 完成${NC}"

        echo -e "${CYAN}[3/5] 清理未使用的卷...${NC}"
        docker volume prune -f > /dev/null 2>&1
        echo -e "${GREEN}  ✓ 完成${NC}"

        echo -e "${CYAN}[4/5] 清理未使用的镜像...${NC}"
        docker image prune -a -f > /dev/null 2>&1
        echo -e "${GREEN}  ✓ 完成${NC}"

        echo -e "${CYAN}[5/5] 清理构建缓存...${NC}"
        docker builder prune -af > /dev/null 2>&1
        echo -e "${GREEN}  ✓ 完成${NC}"

        echo ""
        log_success "全面清理完成！"

        # 显示清理后的状态
        echo ""
        echo -e "${CYAN}清理后的磁盘使用:${NC}"
        docker system df
        echo ""
    else
        log_info "已取消清理"
    fi

    echo ""
    printf "${CYAN}按回车键继续...${NC}"
    read
    echo ""
}

# 显示统计信息
show_stats() {
    log_step "Docker 资源统计分析"

    echo -e "${CYAN}正在收集统计信息...${NC}"
    echo ""

    # 显示概览
    echo -e "${CYAN}磁盘使用概览:${NC}"
    docker system df
    echo ""

    # 详细统计
    echo -e "${CYAN}详细统计信息:${NC}"
    echo ""

    # 容器统计
    CONTAINERS_TOTAL=$(docker ps -a -q | wc -l | tr -d ' ')
    CONTAINERS_RUNNING=$(docker ps -q | wc -l | tr -d ' ')
    CONTAINERS_STOPPED=$((CONTAINERS_TOTAL - CONTAINERS_RUNNING))

    echo -e "${YELLOW}容器统计:${NC}"
    echo -e "  • 总容器数: ${BOLD}$CONTAINERS_TOTAL${NC}"
    echo -e "  • 运行中: ${GREEN}$CONTAINERS_RUNNING${NC}"
    echo -e "  • 已停止: ${YELLOW}$CONTAINERS_STOPPED${NC}"
    echo ""

    # 镜像统计
    IMAGES_TOTAL=$(docker images -q | wc -l | tr -d ' ')
    DANGLING_COUNT=$(docker images -f "dangling=true" -q | wc -l | tr -d ' ')

    echo -e "${YELLOW}镜像统计:${NC}"
    echo -e "  • 总镜像数: ${BOLD}$IMAGES_TOTAL${NC}"
    echo -e "  • 悬空镜像: ${YELLOW}$DANGLING_COUNT${NC}"
    echo ""

    # 卷统计
    VOLUMES_TOTAL=$(docker volume ls -q | wc -l | tr -d ' ')
    echo -e "${YELLOW}卷统计:${NC}"
    echo -e "  • 总卷数: ${BOLD}$VOLUMES_TOTAL${NC}"
    echo ""

    # 网络统计
    NETWORKS_TOTAL=$(docker network ls -q | wc -l | tr -d ' ')
    NETWORKS_DEFAULT=3  # bridge, host, none
    NETWORKS_CUSTOM=$((NETWORKS_TOTAL - NETWORKS_DEFAULT))
    echo -e "${YELLOW}网络统计:${NC}"
    echo -e "  • 总网络数: ${BOLD}$NETWORKS_TOTAL${NC}"
    echo -e "  • 自定义网络: ${BOLD}$NETWORKS_CUSTOM${NC}"
    echo ""

    # 显示清理建议
    echo -e "${CYAN}清理建议:${NC}"
    if [ "$DANGLING_COUNT" -gt 0 ]; then
        echo -e "  ${YELLOW}•${NC} 发现 $DANGLING_COUNT 个悬空镜像，建议清理"
    fi
    if [ "$CONTAINERS_STOPPED" -gt 0 ]; then
        echo -e "  ${YELLOW}•${NC} 发现 $CONTAINERS_STOPPED 个停止的容器"
    fi

    # 获取可回收空间
    CACHE_RECLAIMABLE=$(docker system df | grep "Build Cache" | awk '{print $5}')
    if [ -n "$CACHE_RECLAIMABLE" ] && [ "$CACHE_RECLAIMABLE" != "0B" ]; then
        echo -e "  ${YELLOW}•${NC} 构建缓存可回收: $CACHE_RECLAIMABLE"
    fi

    if [ "$DANGLING_COUNT" -eq 0 ] && [ "$CONTAINERS_STOPPED" -eq 0 ] && [ "$CACHE_RECLAIMABLE" == "0B" ]; then
        echo -e "  ${GREEN}✓${NC} 系统很干净，无需清理"
    fi

    echo ""
    printf "${CYAN}按回车键继续...${NC}"
    read
    echo ""
}

# ================================
# 安装历史和智能卸载功能
# ================================

# 安装历史文件
INSTALL_HISTORY_FILE="$HOME/.bettafish/install-history.log"

# 读取安装历史
read_install_history() {
    if [ ! -f "$INSTALL_HISTORY_FILE" ]; then
        log_warn "未找到安装历史记录"
        echo ""
        log_info "安装历史文件位置: $INSTALL_HISTORY_FILE"
        log_info "可能原因:"
        echo "  • 使用旧版本脚本部署（不支持安装历史）"
        echo "  • 手动部署的 BettaFish"
        echo ""
        return 1
    fi

    return 0
}

# 显示安装历史
show_install_history() {
    if ! read_install_history; then
        return 0
    fi

    log_info "读取安装历史记录..."
    echo ""

    # 读取元数据
    local install_date=$(grep "^install_date=" "$INSTALL_HISTORY_FILE" | head -n1 | cut -d'=' -f2)
    local script_version=$(grep "^script_version=" "$INSTALL_HISTORY_FILE" | head -n1 | cut -d'=' -f2)
    local install_dir=$(grep "^install_dir=" "$INSTALL_HISTORY_FILE" | head -n1 | cut -d'=' -f2)

    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}BettaFish 安装历史${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  安装时间: ${GREEN}$install_date${NC}"
    echo -e "  脚本版本: ${GREEN}$script_version${NC}"
    echo -e "  安装目录: ${CYAN}$install_dir${NC}"
    echo ""
    echo -e "${CYAN}───────────────────────────────────────────────────${NC}"
    echo -e "${BOLD}组件安装记录:${NC}"
    echo ""

    # 解析并显示每个组件
    local current_component=""
    local existed_before=""
    local installed_by_script=""
    local install_date_comp=""
    local version=""

    while IFS= read -r line; do
        # 跳过注释和空行
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue

        # 检测新组件节
        if [[ "$line" =~ ^\[(.+)\]$ ]]; then
            # 显示上一个组件的信息
            if [ -n "$current_component" ] && [ "$current_component" != "metadata" ]; then
                display_component_info "$current_component" "$existed_before" "$installed_by_script" "$install_date_comp" "$version"
            fi

            # 重置变量
            current_component="${BASH_REMATCH[1]}"
            existed_before=""
            installed_by_script=""
            install_date_comp=""
            version=""
            continue
        fi

        # 解析键值对
        if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"

            case "$key" in
                existed_before) existed_before="$value" ;;
                installed_by_script) installed_by_script="$value" ;;
                install_date) install_date_comp="$value" ;;
                version) version="$value" ;;
            esac
        fi
    done < "$INSTALL_HISTORY_FILE"

    # 显示最后一个组件
    if [ -n "$current_component" ] && [ "$current_component" != "metadata" ]; then
        display_component_info "$current_component" "$existed_before" "$installed_by_script" "$install_date_comp" "$version"
    fi

    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
    echo ""
}

# 显示单个组件信息
display_component_info() {
    local component=$1
    local existed_before=$2
    local installed_by_script=$3
    local install_date=$4
    local version=$5

    # 组件名称映射
    local display_name=""
    case "$component" in
        homebrew) display_name="Homebrew" ;;
        docker) display_name="Docker Desktop" ;;
        git) display_name="Git" ;;
        colima) display_name="Colima" ;;
        bettafish) display_name="BettaFish" ;;
        *) display_name="$component" ;;
    esac

    # 图标和状态
    if [ "$installed_by_script" == "true" ]; then
        echo -e "  ${GREEN}✓${NC} ${BOLD}$display_name${NC}"
        [ -n "$version" ] && echo -e "    └─ 版本: ${CYAN}$version${NC}"
        [ -n "$install_date" ] && echo -e "    └─ 安装时间: ${CYAN}$install_date${NC}"
        echo -e "    └─ 由脚本安装: ${GREEN}是${NC}"
        echo -e "    └─ 可以安全卸载: ${GREEN}是${NC}"
    else
        echo -e "  ${YELLOW}○${NC} ${BOLD}$display_name${NC}"
        if [ "$existed_before" == "true" ]; then
            echo -e "    └─ 安装前已存在: ${YELLOW}是${NC}"
            echo -e "    └─ 不建议卸载: ${YELLOW}系统或用户已安装${NC}"
        else
            echo -e "    └─ 未由脚本安装${NC}"
        fi
    fi
    echo ""
}

# 智能卸载 BettaFish - 新版本（用户逐个确认）
uninstall_bettafish() {
    log_step "智能卸载 BettaFish"

    # 检查安装历史
    if ! read_install_history; then
        log_warn "没有安装历史记录，将进行手动卸载"
        echo ""
        manual_uninstall_bettafish
        return
    fi

    # 显示安装历史
    show_install_history

    log_warn "请选择要卸载的组件"
    echo ""

    # 检查哪些组件是脚本安装的
    local has_homebrew=$(grep -A5 "^\[homebrew\]" "$INSTALL_HISTORY_FILE" | grep "installed_by_script=true" 2>/dev/null)
    local has_docker=$(grep -A5 "^\[docker\]" "$INSTALL_HISTORY_FILE" | grep "installed_by_script=true" 2>/dev/null)
    local has_git=$(grep -A5 "^\[git\]" "$INSTALL_HISTORY_FILE" | grep "installed_by_script=true" 2>/dev/null)
    local has_colima=$(grep -A5 "^\[colima\]" "$INSTALL_HISTORY_FILE" | grep "installed_by_script=true" 2>/dev/null)
    local has_bettafish=$(grep -A5 "^\[bettafish\]" "$INSTALL_HISTORY_FILE" | grep "installed_by_script=true" 2>/dev/null)

    # 用户选择变量
    local uninstall_homebrew=false
    local uninstall_docker=false
    local uninstall_git=false
    local uninstall_colima=false
    local uninstall_bettafish=false

    local source_dir=$(grep -A5 "^\[bettafish\]" "$INSTALL_HISTORY_FILE" | grep "^source_dir=" | cut -d'=' -f2 2>/dev/null)

    echo -e "${CYAN}═════════════════════════════════════════════${NC}"
    echo -e "${BOLD}可卸载的组件（由脚本安装）:${NC}"
    echo -e "${CYAN}═════════════════════════════════════════════${NC}"
    echo ""

    # 显示可卸载的组件
    local component_count=0

    if [ -n "$has_bettafish" ]; then
        component_count=$((component_count + 1))
        echo -e "  ${YELLOW}[$component_count]${NC} BettaFish 容器和镜像"
        [ -n "$source_dir" ] && echo "      └─ 源码: $source_dir"
    fi

    if [ -n "$has_docker" ]; then
        component_count=$((component_count + 1))
        echo -e "  ${YELLOW}[$component_count]${NC} Docker Desktop ${RED}(系统工具)${NC}"
    fi

    if [ -n "$has_homebrew" ]; then
        component_count=$((component_count + 1))
        echo -e "  ${YELLOW}[$component_count]${NC} Homebrew ${RED}(系统工具)${NC}"
    fi

    if [ -n "$has_git" ]; then
        component_count=$((component_count + 1))
        echo -e "  ${YELLOW}[$component_count]${NC} Git ${RED}(系统工具)${NC}"
    fi

    if [ -n "$has_colima" ]; then
        component_count=$((component_count + 1))
        echo -e "  ${YELLOW}[$component_count]${NC} Colima"
    fi

    if [ $component_count -eq 0 ]; then
        log_info "没有由脚本安装的组件需要卸载"
        echo ""
        return
    fi

    echo ""
    echo -e "${CYAN}═════════════════════════════════════════════${NC}"
    echo ""
    echo "卸载选项:"
    echo ""
    echo -e "  ${GREEN}a${NC} - 全部卸载 ${RED}(危险!)${NC}"
    echo -e "  ${GREEN}b${NC} - 仅卸载 BettaFish ${GREEN}(推荐)${NC}"
    echo -e "  ${GREEN}c${NC} - 自定义选择"
    echo -e "  ${GREEN}0${NC} - 取消"
    echo ""
    printf "${CYAN}请选择 [a/b/c/0]: ${NC}"
    read UNINSTALL_MODE

    case "$UNINSTALL_MODE" in
        a|A)
            # 全部卸载
            log_warn "将卸载所有由脚本安装的组件!"
            echo ""
            printf "${RED}确认全部卸载? (输入 YES 确认): ${NC}"
            read CONFIRM_ALL
            if [[ "$CONFIRM_ALL" != "YES" ]]; then
                log_info "取消卸载"
                return
            fi

            [ -n "$has_bettafish" ] && uninstall_bettafish=true
            [ -n "$has_docker" ] && uninstall_docker=true
            [ -n "$has_homebrew" ] && uninstall_homebrew=true
            [ -n "$has_git" ] && uninstall_git=true
            [ -n "$has_colima" ] && uninstall_colima=true
            ;;

        b|B)
            # 仅卸载 BettaFish
            if [ -n "$has_bettafish" ]; then
                uninstall_bettafish=true
                log_info "将只卸载 BettaFish"
            else
                log_warn "BettaFish 不是由脚本安装的"
                return
            fi
            ;;

        c|C)
            # 自定义选择
            echo ""
            log_info "请逐个选择要卸载的组件"
            echo ""

            if [ -n "$has_bettafish" ]; then
                printf "${YELLOW}卸载 BettaFish? [Y/n]: ${NC}"
                read resp
                [[ ! "$resp" =~ ^[Nn]$ ]] && uninstall_bettafish=true
            fi

            if [ -n "$has_docker" ]; then
                printf "${YELLOW}卸载 Docker Desktop? ${RED}(系统工具) [y/N]: ${NC}"
                read resp
                [[ "$resp" =~ ^[Yy]$ ]] && uninstall_docker=true
            fi

            if [ -n "$has_homebrew" ]; then
                printf "${YELLOW}卸载 Homebrew? ${RED}(系统工具) [y/N]: ${NC}"
                read resp
                [[ "$resp" =~ ^[Yy]$ ]] && uninstall_homebrew=true
            fi

            if [ -n "$has_git" ]; then
                printf "${YELLOW}卸载 Git? ${RED}(系统工具) [y/N]: ${NC}"
                read resp
                [[ "$resp" =~ ^[Yy]$ ]] && uninstall_git=true
            fi

            if [ -n "$has_colima" ]; then
                printf "${YELLOW}卸载 Colima? [y/N]: ${NC}"
                read resp
                [[ "$resp" =~ ^[Yy]$ ]] && uninstall_colima=true
            fi
            ;;

        0)
            log_info "取消卸载"
            echo ""
            return
            ;;

        *)
            log_error "无效选择"
            echo ""
            return
            ;;
    esac

    # 显示即将卸载的内容
    echo ""
    echo -e "${CYAN}═════════════════════════════════════════════${NC}"
    echo -e "${BOLD}即将卸载:${NC}"
    echo -e "${CYAN}═════════════════════════════════════════════${NC}"
    echo ""

    local will_uninstall_anything=false

    [ "$uninstall_bettafish" = true ] && echo -e "  ${RED}✗${NC} BettaFish" && will_uninstall_anything=true
    [ "$uninstall_docker" = true ] && echo -e "  ${RED}✗${NC} Docker Desktop" && will_uninstall_anything=true
    [ "$uninstall_homebrew" = true ] && echo -e "  ${RED}✗${NC} Homebrew" && will_uninstall_anything=true
    [ "$uninstall_git" = true ] && echo -e "  ${RED}✗${NC} Git" && will_uninstall_anything=true
    [ "$uninstall_colima" = true ] && echo -e "  ${RED}✗${NC} Colima" && will_uninstall_anything=true

    if [ "$will_uninstall_anything" = false ]; then
        log_info "没有选择任何组件"
        echo ""
        return
    fi

    echo ""
    printf "${RED}最终确认? (输入 UNINSTALL): ${NC}"
    read FINAL_CONFIRM

    if [[ "$FINAL_CONFIRM" != "UNINSTALL" ]]; then
        log_info "取消卸载"
        echo ""
        return
    fi

    echo ""
    log_info "开始卸载..."
    echo ""

    # 执行卸载
    if [ "$uninstall_bettafish" = true ]; then
        log_info "停止并删除 BettaFish 容器..."
        docker-compose -f "$source_dir/docker-compose.yml" down 2>/dev/null || true
        docker ps -a | grep bettafish | awk '{print $1}' | xargs docker rm -f 2>/dev/null || true

        log_info "删除 BettaFish 镜像..."
        docker images | grep bettafish | awk '{print $3}' | xargs docker rmi -f 2>/dev/null || true

        if [ -n "$source_dir" ] && [ -d "$source_dir" ]; then
            printf "${YELLOW}删除源码目录? [y/N]: ${NC}"
            read DELETE_SOURCE
            if [[ "$DELETE_SOURCE" =~ ^[Yy]$ ]]; then
                log_info "删除源码: $source_dir"
                rm -rf "$source_dir"
                rmdir "$(dirname "$source_dir")" 2>/dev/null || true
            fi
        fi

        log_success "BettaFish 已卸载"
        echo ""
    fi

    if [ "$uninstall_docker" = true ]; then
        log_warn "卸载 Docker Desktop..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            osascript -e 'quit app "Docker"' 2>/dev/null || true
            sleep 2
            rm -rf /Applications/Docker.app
            rm -rf ~/Library/Group\ Containers/group.com.docker
            rm -rf ~/Library/Containers/com.docker.docker
            rm -rf ~/.docker
            log_success "Docker Desktop 已卸载"
        else
            log_warn "Linux 系统请手动卸载 Docker:"
            echo "  sudo apt-get remove docker-ce docker-ce-cli containerd.io"
        fi
        echo ""
    fi

    if [ "$uninstall_homebrew" = true ]; then
        log_warn "卸载 Homebrew..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)" 2>/dev/null || true
            log_success "Homebrew 已卸载"
        fi
        echo ""
    fi

    if [ "$uninstall_git" = true ]; then
        log_warn "Git 通常为系统自带，建议保留"
        echo "如需卸载，请手动执行:"
        echo "  macOS: brew uninstall git"
        echo "  Ubuntu: sudo apt-get remove git"
        echo ""
    fi

    if [ "$uninstall_colima" = true ]; then
        log_info "卸载 Colima..."
        colima delete 2>/dev/null || true
        brew uninstall colima 2>/dev/null || true
        log_success "Colima 已卸载"
        echo ""
    fi

    # 删除安装历史
    printf "${YELLOW}删除安装历史记录? [y/N]: ${NC}"
    read DELETE_HISTORY
    if [[ "$DELETE_HISTORY" =~ ^[Yy]$ ]]; then
        rm -f "$INSTALL_HISTORY_FILE"
        rmdir "$HOME/.bettafish" 2>/dev/null || true
        log_success "安装历史已删除"
    fi

    echo ""
    log_success "卸载完成！"
    echo ""
}

# 显示清理选项
# 停止服务并清理镜像
stop_and_cleanup_images() {
    log_step "停止服务并清理镜像"

    # 智能检测 BettaFish 目录
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    BETTAFISH_DIR=""

    # 方案1: 查找同级的 BettaFish-main 目录
    if [ -d "$SCRIPT_DIR/BettaFish-main" ] && [ -f "$SCRIPT_DIR/BettaFish-main/docker-compose.yml" ]; then
        BETTAFISH_DIR="$SCRIPT_DIR/BettaFish-main"
    # 方案2: 在当前工作目录查找
    elif [ -d "./BettaFish-main" ] && [ -f "./BettaFish-main/docker-compose.yml" ]; then
        BETTAFISH_DIR="./BettaFish-main"
    # 方案3: 使用运行中的容器信息反推
    elif docker ps --format '{{.Label "com.docker.compose.project.working_dir"}}' 2>/dev/null | grep -q "BettaFish-main"; then
        BETTAFISH_DIR=$(docker ps --format '{{.Label "com.docker.compose.project.working_dir"}}' 2>/dev/null | grep "BettaFish-main" | head -1)
    fi

    if [ -n "$BETTAFISH_DIR" ] && [ -d "$BETTAFISH_DIR" ]; then
        cd "$BETTAFISH_DIR"

        RUNNING_CONTAINERS=$(docker compose ps -q 2>/dev/null | wc -l | tr -d ' ')

        echo -e "${CYAN}当前状态:${NC}"
        echo ""
        docker compose ps 2>/dev/null || echo "  无运行中的容器"
        echo ""

        if [ "$RUNNING_CONTAINERS" -gt 0 ]; then
            echo -e "${YELLOW}⚠️  即将执行的操作:${NC}"
            echo "  1. 停止所有 BettaFish 容器"
            echo "  2. 删除容器"
            echo "  3. 删除镜像 (ghcr.nju.edu.cn/666ghj/bettafish:latest)"
            echo "  4. 删除镜像 (postgres:15)"
            echo ""
            echo -e "${RED}⚠️  警告:${NC}"
            echo "  • 当前服务将停止运行"
            echo "  • 下次部署需重新下载约 10GB 镜像"
            echo "  • 数据库数据会保留（使用 Docker volume）"
            echo ""

            printf "${YELLOW}确认停止服务并清理镜像? [y/N]: ${NC}"
            read CONFIRM
            CONFIRM=$(echo "$CONFIRM" | tr '[:upper:]' '[:lower:]')

            if [[ "$CONFIRM" == "y" ]]; then
                echo ""
                log_info "正在停止服务..."
                docker compose down
                log_success "服务已停止"
                echo ""

                log_info "正在删除镜像..."

                # 删除 BettaFish 镜像
                if docker images -q "ghcr.nju.edu.cn/666ghj/bettafish:latest" >/dev/null 2>&1; then
                    docker rmi "ghcr.nju.edu.cn/666ghj/bettafish:latest" 2>/dev/null && \
                        log_success "已删除: ghcr.nju.edu.cn/666ghj/bettafish:latest" || \
                        log_warn "删除失败: ghcr.nju.edu.cn/666ghj/bettafish:latest"
                fi

                # 删除 PostgreSQL 镜像
                if docker images -q "postgres:15" >/dev/null 2>&1; then
                    docker rmi "postgres:15" 2>/dev/null && \
                        log_success "已删除: postgres:15" || \
                        log_warn "删除失败: postgres:15"
                fi

                echo ""
                log_success "清理完成！"
                echo ""
                log_info "磁盘空间已释放约 10GB"
                echo ""
            else
                log_info "已取消操作"
                echo ""
            fi
        else
            log_warn "没有运行中的 BettaFish 容器"
            echo ""
            log_info "提示: 如果需要删除镜像，请先确保容器已停止"
            echo ""
        fi
    else
        log_error "找不到 BettaFish 部署目录"
        echo ""
        log_info "诊断信息:"
        echo ""
        echo "  脚本位置: $SCRIPT_DIR"
        echo "  检测结果: 未找到 docker-compose.yml"
        echo ""
        log_info "可能的原因:"
        echo "  1. BettaFish 未部署或已删除"
        echo "  2. 目录结构不正确"
        echo ""
        log_info "解决方案:"
        echo "  • 方案1: 进入 BettaFish-main 目录后运行此脚本"
        echo "  • 方案2: 手动停止服务："
        echo "    cd BettaFish-main && docker compose down"
        echo "    docker rmi ghcr.nju.edu.cn/666ghj/bettafish:latest"
        echo "    docker rmi postgres:15"
        echo ""

        # 尝试显示现有的容器
        BETTAFISH_CONTAINERS=$(docker ps -a --filter "name=bettafish" --format "{{.Names}}" 2>/dev/null)
        if [ -n "$BETTAFISH_CONTAINERS" ]; then
            log_info "检测到 BettaFish 相关容器:"
            echo "$BETTAFISH_CONTAINERS" | while read container; do
                echo "  • $container"
            done
            echo ""
        fi
    fi

    printf "${CYAN}按回车键继续...${NC}"
    read
    echo ""
}

# 主菜单循环
main_menu() {
    while true; do
        get_docker_disk_usage
        show_cleanup_options

        printf "${CYAN}请选择 [0-8]: ${NC}"
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
            6)
                show_install_history
                echo ""
                printf "${CYAN}按回车键继续...${NC}"
                read
                ;;
            7)
                uninstall_bettafish
                ;;
            8)
                stop_and_cleanup_images
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
