#!/bin/bash
# BettaFish 一键安装脚本
# 版本: v2.1
# 使用方法: curl -fsSL https://raw.githubusercontent.com/Jascenn/deployment-scripts-hub/main/bettafish/install.sh | bash

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# 日志函数
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_step() { echo -e "\n${CYAN}${BOLD}▶ $1${NC}\n"; }

# 显示 Banner
echo -e "${BLUE}"
cat << "EOF"
  _      ___ ___  _   _  ____ ____       _    ___
 | |    |_ _/ _ \| \ | |/ ___/ ___|     / \  |_ _|
 | |     | | | | |  \| | |  | |        / _ \  | |
 | |___  | | |_| | |\  | |__| |___  _ / ___ \ | |
 |_____||___\___/|_| \_|\____\____|(_)_/   \_\___|

       🐟 BettaFish 一键安装
        Powered by LIONCC.AI
EOF
echo -e "${NC}\n"

# 默认参数
PROXY=""
DEPLOY_DIR="${HOME}/bettafish-$(date +%Y%m%d_%H%M%S)"
SKIP_ENV_CHECK=false
GITHUB_REPO="https://github.com/666ghj/BettaFish"
GITHUB_BRANCH="main"
SCRIPT_REPO="https://raw.githubusercontent.com/Jascenn/deployment-scripts-hub/main/bettafish"

# 参数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        --proxy)
            PROXY="$2"
            shift 2
            ;;
        --dir)
            DEPLOY_DIR="$2"
            shift 2
            ;;
        --skip-env-check)
            SKIP_ENV_CHECK=true
            shift
            ;;
        --help)
            cat << "HELP"
BettaFish 一键安装脚本

使用方法:
  curl -fsSL https://raw.githubusercontent.com/Jascenn/deployment-scripts-hub/main/bettafish/install.sh | bash
  curl -fsSL https://raw.githubusercontent.com/Jascenn/deployment-scripts-hub/main/bettafish/install.sh | bash -s -- [选项]

选项:
  --proxy PROXY       设置代理 (例如: http://127.0.0.1:7890)
  --dir DIR           指定部署目录 (默认: ~/bettafish-日期时间)
  --skip-env-check    跳过环境检查
  --help              显示此帮助信息

示例:
  # 基础安装
  curl -fsSL https://raw.githubusercontent.com/Jascenn/deployment-scripts-hub/main/bettafish/install.sh | bash

  # 使用代理
  curl -fsSL https://raw.githubusercontent.com/Jascenn/deployment-scripts-hub/main/bettafish/install.sh | bash -s -- --proxy http://127.0.0.1:7890

  # 指定目录
  curl -fsSL https://raw.githubusercontent.com/Jascenn/deployment-scripts-hub/main/bettafish/install.sh | bash -s -- --dir ~/my-bettafish

  # 组合参数
  curl -fsSL https://raw.githubusercontent.com/Jascenn/deployment-scripts-hub/main/bettafish/install.sh | bash -s -- \
    --proxy http://127.0.0.1:7890 \
    --dir ~/bettafish
HELP
            exit 0
            ;;
        *)
            log_error "未知参数: $1"
            echo "使用 --help 查看帮助信息"
            exit 1
            ;;
    esac
done

# ================================
# 步骤 0: 环境检查
# ================================

log_step "步骤 0: 环境检查"

# 设置代理
if [ -n "$PROXY" ]; then
    export HTTP_PROXY="$PROXY"
    export HTTPS_PROXY="$PROXY"
    export http_proxy="$PROXY"
    export https_proxy="$PROXY"
    log_success "已设置代理: $PROXY"
fi

# 检查必需命令
if ! $SKIP_ENV_CHECK; then
    log_info "检查必需工具..."

    # 检查 curl
    if ! command -v curl &> /dev/null; then
        log_error "未找到 curl 命令"
        exit 1
    fi

    # 检查 git
    if ! command -v git &> /dev/null; then
        log_error "未找到 git 命令，请先安装 git"
        echo ""
        echo "安装方法:"
        echo "  macOS: brew install git"
        echo "  Ubuntu/Debian: sudo apt-get install git"
        echo "  CentOS/RHEL: sudo yum install git"
        exit 1
    fi

    # 检查 Docker
    log_info "检查 Docker 是否安装..."
    if ! command -v docker &> /dev/null; then
        log_error "未检测到 Docker，请先安装 Docker Desktop"
        echo ""
        echo "安装链接:"
        echo "  macOS/Windows: https://www.docker.com/products/docker-desktop"
        echo "  Linux: https://docs.docker.com/engine/install/"
        exit 1
    fi
    log_success "Docker 已安装"

    log_info "检查 Docker 是否运行..."
    if ! docker info > /dev/null 2>&1; then
        log_warn "Docker 未运行，部署时需要启动 Docker Desktop"
        echo ""
        log_info "您可以先下载脚本，稍后启动 Docker 再执行部署"
        echo ""
    else
        log_success "Docker 正在运行"
    fi
fi

# ================================
# 步骤 1: 下载部署脚本
# ================================

log_step "步骤 1: 下载部署脚本"

log_info "创建部署目录: $DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR"
cd "$DEPLOY_DIR"

log_info "下载 docker-deploy.sh..."
if ! curl -fsSL "$SCRIPT_REPO/docker-deploy.sh" -o docker-deploy.sh; then
    log_error "下载部署脚本失败"
    exit 1
fi
chmod +x docker-deploy.sh
log_success "部署脚本下载完成"

log_info "下载 docker-cleanup.sh..."
if ! curl -fsSL "$SCRIPT_REPO/docker-cleanup.sh" -o docker-cleanup.sh 2>/dev/null; then
    log_warn "清理脚本下载失败（可选，不影响部署）"
else
    chmod +x docker-cleanup.sh
    log_success "清理脚本下载完成"
fi

# ================================
# 步骤 2: 执行部署
# ================================

log_step "步骤 2: 执行部署脚本"

log_info "开始部署 BettaFish..."
echo ""

# 传递代理环境变量给部署脚本
if [ -n "$PROXY" ]; then
    export HTTP_PROXY="$PROXY"
    export HTTPS_PROXY="$PROXY"
fi

# 执行部署脚本
log_info "准备执行部署..."
chmod +x docker-deploy.sh

# 直接执行部署脚本
log_info "开始执行部署脚本..."
echo ""

# 如果从管道执行（如 curl | bash），需要重定向 stdin 到 /dev/tty 以支持交互式输入
if [ ! -t 0 ]; then
    # stdin 不是终端，尝试从 /dev/tty 读取（如果可用）
    if [ -e /dev/tty ]; then
        if ! bash ./docker-deploy.sh < /dev/tty; then
            log_error "部署失败"
            echo ""
            echo "部署目录: $DEPLOY_DIR"
            echo "您可以手动执行: cd $DEPLOY_DIR && ./docker-deploy.sh"
            exit 1
        fi
    else
        log_error "检测到非交互式环境且无法访问终端"
        log_info "请在终端中手动执行部署脚本："
        echo ""
        echo -e "${BOLD}${GREEN}cd $DEPLOY_DIR && ./docker-deploy.sh${NC}"
        echo ""
        exit 1
    fi
else
    # stdin 是终端，正常执行
    if ! bash ./docker-deploy.sh; then
        log_error "部署失败"
        echo ""
        echo "部署目录: $DEPLOY_DIR"
        echo "您可以手动执行: cd $DEPLOY_DIR && ./docker-deploy.sh"
        exit 1
    fi
fi

# ================================
# 完成
# ================================

log_step "✅ 安装完成！"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}${BOLD}🎉 BettaFish 已成功安装！${NC}"
echo ""
echo "📍 安装信息:"
echo "  脚本目录: $DEPLOY_DIR"
echo "  源码目录: $DEPLOY_DIR/BettaFish-main (由 docker-deploy.sh 自动下载)"
echo "  访问地址: http://localhost:8501"
echo ""
echo "🔧 下一步操作:"
echo "  1. 配置 API 密钥 (如需要):"
echo "     cd $DEPLOY_DIR/BettaFish-main"
echo "     nano .env"
echo ""
echo "  2. 重启服务:"
echo "     cd $DEPLOY_DIR/BettaFish-main"
echo "     docker-compose restart"
echo ""
echo "  3. 访问应用:"
echo "     http://localhost:8501"
echo ""
echo "🚀 常用命令:"
echo "  查看容器: docker ps"
echo "  查看日志: cd $DEPLOY_DIR/BettaFish-main && docker-compose logs -f"
echo "  停止服务: cd $DEPLOY_DIR/BettaFish-main && docker-compose down"
echo "  重启服务: cd $DEPLOY_DIR/BettaFish-main && docker-compose restart"
echo ""
echo "📚 更多帮助:"
echo "  文档: https://github.com/Jascenn/deployment-scripts-hub/tree/main/bettafish"
echo "  问题: https://github.com/Jascenn/deployment-scripts-hub/issues"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
