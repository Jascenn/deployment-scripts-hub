#!/bin/bash
# BettaFish 智能一键部署脚本
# 版本: v1.0
# 使用方法: curl -fsSL https://example.com/smart-deploy.sh | bash

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

       🐟 智能一键部署
        Powered by LIONCC.AI
EOF
echo -e "${NC}\n"

# 默认参数
PROXY=""
MINIMAL=false
DEPLOY_DIR="/tmp/bettafish-deploy-$(date +%s)"
BASE_URL=""
SKIP_ENV_CHECK=false

# 参数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        --proxy)
            PROXY="$2"
            shift 2
            ;;
        --minimal)
            MINIMAL=true
            shift
            ;;
        --dir)
            DEPLOY_DIR="$2"
            shift 2
            ;;
        --url)
            BASE_URL="$2"
            shift 2
            ;;
        --skip-env-check)
            SKIP_ENV_CHECK=true
            shift
            ;;
        --help)
            cat << "HELP"
BettaFish 智能一键部署脚本

使用方法:
  curl -fsSL https://example.com/smart-deploy.sh | bash
  curl -fsSL https://example.com/smart-deploy.sh | bash -s -- [选项]

选项:
  --proxy PROXY       设置代理 (例如: http://127.0.0.1:7890)
  --minimal           使用最小核心包（约3MB，缺少文档）
  --dir DIR           指定部署目录 (默认: /tmp/bettafish-deploy-*)
  --url URL           指定下载地址 (默认: 自动检测)
  --skip-env-check    跳过环境检查
  --help              显示此帮助信息

示例:
  # 基础部署
  curl -fsSL https://example.com/smart-deploy.sh | bash

  # 使用代理
  curl -fsSL https://example.com/smart-deploy.sh | bash -s -- --proxy http://127.0.0.1:7890

  # 最小化部署
  curl -fsSL https://example.com/smart-deploy.sh | bash -s -- --minimal

  # 指定目录
  curl -fsSL https://example.com/smart-deploy.sh | bash -s -- --dir ~/bettafish

  # 组合参数
  curl -fsSL https://example.com/smart-deploy.sh | bash -s -- \
    --proxy http://127.0.0.1:7890 \
    --minimal \
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

log_step "步骤 0: 环境检查"

# 设置代理
if [ -n "$PROXY" ]; then
    export HTTP_PROXY="$PROXY"
    export HTTPS_PROXY="$PROXY"
    export http_proxy="$PROXY"
    export https_proxy="$PROXY"
    log_success "已设置代理: $PROXY"
fi

# 检查 Docker
if ! $SKIP_ENV_CHECK; then
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

# 检测网络环境
log_step "步骤 1: 网络环境检测"

if [ -z "$BASE_URL" ]; then
    log_info "检测网络环境..."

    # 测试 GitHub 连接
    if curl -s --connect-timeout 3 https://github.com > /dev/null 2>&1; then
        NETWORK="international"
        BASE_URL="https://github.com/USER/REPO/releases/download/v1.0"
        log_success "检测到国际网络，使用 GitHub"
    else
        NETWORK="domestic"
        BASE_URL="https://gitee.com/USER/REPO/releases/download/v1.0"
        log_success "检测到国内网络，使用 Gitee 镜像"
    fi
else
    log_info "使用指定 URL: $BASE_URL"
fi

# 选择包
log_step "步骤 2: 选择部署包"

if [ "$MINIMAL" = true ]; then
    PACKAGE="BettaFish-Minimal.tar.gz"
    PACKAGE_SIZE="~3MB"
    log_info "使用最小核心包（7个文件）"
    log_warn "注意: 最小包不含可视化文档"
else
    PACKAGE="BettaFish-Deployment-Kit.tar.gz"
    PACKAGE_SIZE="~10MB"
    log_info "使用完整部署包"
fi

echo ""
echo "部署包信息:"
echo "  名称: $PACKAGE"
echo "  大小: $PACKAGE_SIZE"
echo "  目录: $DEPLOY_DIR"
echo ""

# 下载
log_step "步骤 3: 下载部署包"

log_info "正在下载 $PACKAGE ..."
mkdir -p "$DEPLOY_DIR"
cd "$DEPLOY_DIR"

DOWNLOAD_URL="$BASE_URL/$PACKAGE"

if ! curl -fsSL "$DOWNLOAD_URL" -o package.tar.gz; then
    log_error "下载失败"
    echo ""
    echo "可能的原因:"
    echo "  1. 网络连接问题"
    echo "  2. URL 不正确: $DOWNLOAD_URL"
    echo "  3. 需要配置代理"
    echo ""
    echo "请尝试:"
    echo "  1. 使用代理: --proxy http://127.0.0.1:7890"
    echo "  2. 手动下载: curl -L $DOWNLOAD_URL -o package.tar.gz"
    exit 1
fi

log_success "下载完成"

# 解压
log_step "步骤 4: 解压文件"

log_info "正在解压..."
if ! tar -xzf package.tar.gz; then
    log_error "解压失败，文件可能已损坏"
    exit 1
fi

# 查找部署目录
if [ -d "BettaFish-Deployment-Kit" ]; then
    PROJECT_DIR="BettaFish-Deployment-Kit"
elif [ -d "BettaFish-Deployment-Kit-Minimal" ]; then
    PROJECT_DIR="BettaFish-Deployment-Kit-Minimal"
else
    log_error "未找到项目目录"
    exit 1
fi

cd "$PROJECT_DIR"
log_success "解压完成"

# 显示文件列表
echo ""
echo "文件列表:"
ls -lh | head -10
echo ""

# 执行部署
log_step "步骤 5: 执行部署脚本"

if [ ! -f "docker-deploy.sh" ]; then
    log_error "未找到 docker-deploy.sh"
    exit 1
fi

log_info "开始执行部署..."
echo ""

# 传递代理配置
if [ -n "$PROXY" ]; then
    export HTTP_PROXY="$PROXY"
    export HTTPS_PROXY="$PROXY"
fi

# 执行部署脚本
if ! bash docker-deploy.sh; then
    log_error "部署失败"
    echo ""
    echo "部署目录: $DEPLOY_DIR/$PROJECT_DIR"
    echo "请检查上方错误信息，或手动进入目录排查问题"
    exit 1
fi

# 部署成功
log_step "✅ 部署完成！"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}${BOLD}🎉 BettaFish 已成功部署！${NC}"
echo ""
echo "📍 部署信息:"
echo "  目录: $DEPLOY_DIR/$PROJECT_DIR"
echo "  网址: http://localhost:8501"
echo ""
echo "🚀 快速操作:"
echo "  查看容器: docker ps"
echo "  查看日志: docker logs bettafish"
echo "  停止服务: docker-compose down"
echo "  重启服务: docker-compose restart"
echo ""
echo "📚 文档位置:"
if [ "$MINIMAL" = false ]; then
    echo "  可视化: $DEPLOY_DIR/$PROJECT_DIR/最新文档/部署流程可视化_v2.1.html"
fi
echo "  指南: $DEPLOY_DIR/$PROJECT_DIR/最新文档/终极部署指南.md"
echo ""
echo "❓ 遇到问题?"
echo "  查看文档: $DEPLOY_DIR/$PROJECT_DIR/README.md"
echo "  官方仓库: https://github.com/666ghj/BettaFish"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
