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
  ____       _   _        _____ _     _
 |  _ \     | | | |      |  ___(_)   | |
 | |_) | ___| |_| |_ __ _| |_   _ ___| |__
 |  _ < / _ \ __| __/ _` |  _| | / __| '_ \
 | |_) |  __/ |_| || (_| | |   | \__ \ | | |
 |____/ \___|\__|\__\__,_|_|   |_|___/_| |_|

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
        log_error "Docker 未运行，请启动 Docker Desktop"
        exit 1
    fi
    log_success "Docker 正在运行"
fi

# ================================
# 步骤 1: 下载 BettaFish 源码
# ================================

log_step "步骤 1: 下载 BettaFish 源码"

log_info "创建部署目录: $DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR"
cd "$DEPLOY_DIR"

log_info "克隆 BettaFish 仓库..."
if ! git clone --depth 1 --branch "$GITHUB_BRANCH" "$GITHUB_REPO" BettaFish-main 2>&1 | grep -v "Cloning into"; then
    log_error "克隆失败"
    echo ""
    echo "可能的原因:"
    echo "  1. 网络连接问题"
    echo "  2. GitHub 访问受限"
    echo "  3. 需要使用代理"
    echo ""
    echo "请尝试:"
    echo "  使用代理: --proxy http://127.0.0.1:7890"
    exit 1
fi
log_success "源码下载完成"

# ================================
# 步骤 2: 下载部署脚本
# ================================

log_step "步骤 2: 下载部署脚本"

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
# 步骤 3: 准备配置文件
# ================================

log_step "步骤 3: 准备配置文件"

cd BettaFish-main

if [ -f ".env.example" ] && [ ! -f ".env" ]; then
    log_info "创建 .env 配置文件..."
    cp .env.example .env
    log_success ".env 文件已创建"
    log_warn "请稍后编辑 .env 文件配置 API 密钥"
else
    log_info ".env 文件已存在，跳过创建"
fi

cd ..

# ================================
# 步骤 4: 执行部署
# ================================

log_step "步骤 4: 执行部署脚本"

log_info "开始部署 BettaFish..."
echo ""

# 传递代理环境变量给部署脚本
if [ -n "$PROXY" ]; then
    export HTTP_PROXY="$PROXY"
    export HTTPS_PROXY="$PROXY"
fi

# 执行部署脚本（移除 clear 命令以支持 curl 管道执行）
if ! bash docker-deploy.sh; then
    log_error "部署失败"
    echo ""
    echo "部署目录: $DEPLOY_DIR"
    echo "请检查上方错误信息"
    exit 1
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
echo "  部署目录: $DEPLOY_DIR"
echo "  源码目录: $DEPLOY_DIR/BettaFish-main"
echo "  访问地址: http://localhost:8501"
echo ""
echo "🔧 下一步操作:"
echo "  1. 配置 API 密钥:"
echo "     cd $DEPLOY_DIR/BettaFish-main"
echo "     nano .env"
echo ""
echo "  2. 重启服务:"
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
