#!/bin/bash

# BettaFish 部署工具包 - 交互式菜单
# 使用方法: ./menu.sh

# 切换到脚本所在目录
cd "$(dirname "$0")"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# 检测操作系统
OS_TYPE=$(uname -s)

# 清屏
clear_screen() {
    clear
}

# 显示标题
show_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                                                ║${NC}"
    echo -e "${BLUE}║${NC}        🐟 ${BOLD}${CYAN}BettaFish 部署工具包菜单${NC}${BLUE}           ║${NC}"
    echo -e "${BLUE}║                                                ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
    echo ""
}

# 显示菜单
show_menu() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${PURPLE}${BOLD}主菜单${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${GREEN}1${NC}. 🚀 开始部署 BettaFish"
    echo -e "  ${GREEN}2${NC}. 📖 查看文档"
    echo -e "  ${GREEN}3${NC}. 🔍 运行诊断"
    echo -e "  ${GREEN}4${NC}. 🗑️  清理环境"
    echo -e "  ${GREEN}5${NC}. 📊 查看日志"
    echo -e "  ${GREEN}6${NC}. 🔧 工具箱"
    echo -e "  ${GREEN}7${NC}. ℹ️  系统信息"
    echo -e "  ${GREEN}0${NC}. ❌ 退出"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# 显示文档菜单
show_docs_menu() {
    clear_screen
    show_header
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${PURPLE}${BOLD}文档菜单${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${GREEN}1${NC}. 📱 打开完整指南 (HTML)"
    echo -e "  ${GREEN}2${NC}. 📄 查看使用手册 (Markdown)"
    echo -e "  ${GREEN}3${NC}. ⚡ 查看快速参考"
    echo -e "  ${GREEN}4${NC}. 📁 查看目录结构"
    echo -e "  ${GREEN}5${NC}. 📖 查看文档 README"
    echo -e "  ${GREEN}0${NC}. ↩️  返回主菜单"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# 显示工具箱菜单
show_tools_menu() {
    clear_screen
    show_header
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${PURPLE}${BOLD}工具箱${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${GREEN}1${NC}. 🔍 系统诊断"
    echo -e "  ${GREEN}2${NC}. 🗑️  Docker 清理"
    echo -e "  ${GREEN}3${NC}. 📋 日志清理"
    echo -e "  ${GREEN}4${NC}. 📦 检查磁盘空间"
    echo -e "  ${GREEN}5${NC}. 🐳 Docker 状态"
    echo -e "  ${GREEN}6${NC}. 📊 容器状态"
    echo -e "  ${GREEN}0${NC}. ↩️  返回主菜单"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# 打开文件（跨平台）
open_file() {
    local file=$1
    if [ "$OS_TYPE" = "Darwin" ]; then
        open "$file"
    elif command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$file"
    elif command -v firefox >/dev/null 2>&1; then
        firefox "$file"
    else
        echo -e "${YELLOW}⚠️  无法自动打开文件，请手动打开: $file${NC}"
    fi
}

# 查看文本文件
view_text() {
    local file=$1
    if command -v less >/dev/null 2>&1; then
        less "$file"
    else
        cat "$file"
        echo ""
        read -p "按 Enter 键继续..."
    fi
}

# 开始部署
start_deployment() {
    clear_screen
    echo -e "${GREEN}${BOLD}🚀 开始部署 BettaFish...${NC}"
    echo ""

    if [ ! -f "docker-deploy.sh" ]; then
        echo -e "${RED}❌ 错误: 找不到 docker-deploy.sh${NC}"
        echo ""
        read -p "按 Enter 键返回主菜单..."
        return
    fi

    echo -e "${CYAN}即将执行部署脚本...${NC}"
    echo ""
    sleep 1

    bash docker-deploy.sh

    echo ""
    read -p "按 Enter 键返回主菜单..."
}

# 运行诊断
run_diagnose() {
    clear_screen
    echo -e "${GREEN}${BOLD}🔍 运行系统诊断...${NC}"
    echo ""

    if [ -f "diagnose.sh" ]; then
        bash diagnose.sh
    elif [ -f "tools/diagnose.sh" ]; then
        bash tools/diagnose.sh
    else
        echo -e "${RED}❌ 错误: 找不到诊断脚本${NC}"
    fi

    echo ""
    read -p "按 Enter 键返回主菜单..."
}

# 清理环境
cleanup_env() {
    clear_screen
    echo -e "${YELLOW}${BOLD}🗑️  清理 Docker 环境${NC}"
    echo ""
    echo -e "${RED}警告: 此操作将停止并删除所有 BettaFish 相关容器！${NC}"
    echo ""
    read -p "确认继续？(yes/no): " confirm

    if [ "$confirm" = "yes" ]; then
        if [ -f "docker-cleanup.sh" ]; then
            bash docker-cleanup.sh
        elif [ -f "tools/docker-cleanup.sh" ]; then
            bash tools/docker-cleanup.sh
        else
            echo -e "${RED}❌ 错误: 找不到清理脚本${NC}"
        fi
    else
        echo -e "${CYAN}已取消清理操作${NC}"
    fi

    echo ""
    read -p "按 Enter 键返回主菜单..."
}

# 查看日志
view_logs() {
    clear_screen
    echo -e "${GREEN}${BOLD}📊 部署日志${NC}"
    echo ""

    if [ -d "logs" ] && [ "$(ls -A logs 2>/dev/null)" ]; then
        echo -e "${CYAN}可用的日志文件:${NC}"
        echo ""
        ls -lht logs/ | head -10
        echo ""
        echo -e "${YELLOW}最新日志文件内容 (最后50行):${NC}"
        echo ""
        latest_log=$(ls -t logs/*.log 2>/dev/null | head -1)
        if [ -n "$latest_log" ]; then
            tail -50 "$latest_log"
        else
            echo -e "${RED}未找到日志文件${NC}"
        fi
    else
        echo -e "${YELLOW}日志目录为空${NC}"
    fi

    echo ""
    read -p "按 Enter 键返回主菜单..."
}

# 处理文档菜单
handle_docs_menu() {
    while true; do
        show_docs_menu
        read -p "请选择操作 [0-5]: " choice

        case $choice in
            1)
                echo -e "${GREEN}正在打开完整指南...${NC}"
                if [ -f "docs/用户完整指南.html" ]; then
                    open_file "docs/用户完整指南.html"
                elif [ -f "Guides/用户完整指南.html" ]; then
                    open_file "Guides/用户完整指南.html"
                else
                    echo -e "${RED}❌ 找不到文件${NC}"
                fi
                sleep 1
                ;;
            2)
                clear_screen
                if [ -f "docs/用户使用手册.md" ]; then
                    view_text "docs/用户使用手册.md"
                elif [ -f "Guides/用户使用手册.md" ]; then
                    view_text "Guides/用户使用手册.md"
                else
                    echo -e "${RED}❌ 找不到文件${NC}"
                    read -p "按 Enter 键继续..."
                fi
                ;;
            3)
                clear_screen
                if [ -f "docs/快速参考卡片.md" ]; then
                    view_text "docs/快速参考卡片.md"
                elif [ -f "Guides/快速参考卡片.md" ]; then
                    view_text "Guides/快速参考卡片.md"
                else
                    echo -e "${RED}❌ 找不到文件${NC}"
                    read -p "按 Enter 键继续..."
                fi
                ;;
            4)
                echo -e "${GREEN}正在打开目录结构说明...${NC}"
                if [ -f "docs/文件夹结构说明.html" ]; then
                    open_file "docs/文件夹结构说明.html"
                elif [ -f "Guides/文件夹结构说明.html" ]; then
                    open_file "Guides/文件夹结构说明.html"
                else
                    echo -e "${RED}❌ 找不到文件${NC}"
                fi
                sleep 1
                ;;
            5)
                clear_screen
                if [ -f "docs/README.md" ]; then
                    view_text "docs/README.md"
                elif [ -f "Guides/README.md" ]; then
                    view_text "Guides/README.md"
                else
                    echo -e "${RED}❌ 找不到文件${NC}"
                    read -p "按 Enter 键继续..."
                fi
                ;;
            0)
                break
                ;;
            *)
                echo -e "${RED}❌ 无效选择${NC}"
                sleep 1
                ;;
        esac
    done
}

# 处理工具箱菜单
handle_tools_menu() {
    while true; do
        show_tools_menu
        read -p "请选择操作 [0-6]: " choice

        case $choice in
            1)
                run_diagnose
                ;;
            2)
                cleanup_env
                ;;
            3)
                clear_screen
                echo -e "${GREEN}${BOLD}📋 清理日志文件${NC}"
                echo ""
                if [ -f "log-cleanup.sh" ]; then
                    bash log-cleanup.sh
                elif [ -f "tools/log-cleanup.sh" ]; then
                    bash tools/log-cleanup.sh
                else
                    echo -e "${YELLOW}日志清理脚本不存在，正在手动清理...${NC}"
                    if [ -d "logs" ]; then
                        log_count=$(ls logs/*.log 2>/dev/null | wc -l)
                        if [ "$log_count" -gt 5 ]; then
                            echo "发现 $log_count 个日志文件，保留最新5个..."
                            ls -t logs/*.log | tail -n +6 | xargs rm -f
                            echo -e "${GREEN}✅ 清理完成${NC}"
                        else
                            echo "日志文件数量: $log_count (无需清理)"
                        fi
                    fi
                fi
                echo ""
                read -p "按 Enter 键继续..."
                ;;
            4)
                clear_screen
                echo -e "${GREEN}${BOLD}📦 磁盘空间检查${NC}"
                echo ""
                df -h . | head -2
                echo ""
                echo -e "${CYAN}目录大小:${NC}"
                du -sh * 2>/dev/null | sort -h
                echo ""
                read -p "按 Enter 键继续..."
                ;;
            5)
                clear_screen
                echo -e "${GREEN}${BOLD}🐳 Docker 状态${NC}"
                echo ""
                docker version 2>/dev/null || echo -e "${RED}Docker 未安装或未运行${NC}"
                echo ""
                read -p "按 Enter 键继续..."
                ;;
            6)
                clear_screen
                echo -e "${GREEN}${BOLD}📊 容器状态${NC}"
                echo ""
                docker ps -a --filter "name=bettafish" 2>/dev/null || echo -e "${RED}无法获取容器状态${NC}"
                echo ""
                read -p "按 Enter 键继续..."
                ;;
            0)
                break
                ;;
            *)
                echo -e "${RED}❌ 无效选择${NC}"
                sleep 1
                ;;
        esac
    done
}

# 显示系统信息
show_system_info() {
    clear_screen
    echo -e "${GREEN}${BOLD}ℹ️  系统信息${NC}"
    echo ""
    echo -e "${CYAN}操作系统:${NC} $OS_TYPE"
    echo -e "${CYAN}主机名:${NC} $(hostname)"
    echo -e "${CYAN}用户:${NC} $USER"
    echo -e "${CYAN}工作目录:${NC} $(pwd)"
    echo ""
    echo -e "${CYAN}Docker 版本:${NC}"
    docker --version 2>/dev/null || echo "  未安装"
    echo ""
    echo -e "${CYAN}磁盘空间:${NC}"
    df -h . | tail -1 | awk '{print "  可用: " $4 " / " $2 " (使用率: " $5 ")"}'
    echo ""
    echo -e "${CYAN}当前时间:${NC} $(date)"
    echo ""
    read -p "按 Enter 键返回主菜单..."
}

# 主循环
main() {
    while true; do
        clear_screen
        show_header
        show_menu
        read -p "请选择操作 [0-7]: " choice

        case $choice in
            1)
                start_deployment
                ;;
            2)
                handle_docs_menu
                ;;
            3)
                run_diagnose
                ;;
            4)
                cleanup_env
                ;;
            5)
                view_logs
                ;;
            6)
                handle_tools_menu
                ;;
            7)
                show_system_info
                ;;
            0)
                clear_screen
                echo ""
                echo -e "${GREEN}👋 感谢使用 BettaFish 部署工具包！再见！${NC}"
                echo ""
                exit 0
                ;;
            *)
                echo -e "${RED}❌ 无效选择，请输入 0-7${NC}"
                sleep 1
                ;;
        esac
    done
}

# 运行主程序
main
