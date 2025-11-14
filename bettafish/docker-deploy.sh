#!/bin/bash
# BettaFish Docker 一键部署脚本
# 版本: v1.0
# 使用方法: ./docker-deploy.sh

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# 显示 Logo
clear
echo -e "${BLUE}"
cat << "EOF"
  _      ___ ___  _   _  ____ ____       _    ___
 | |    |_ _/ _ \| \ | |/ ___/ ___|     / \  |_ _|
 | |     | | | | |  \| | |  | |        / _ \  | |
 | |___  | | |_| | |\  | |__| |___  _ / ___ \ | |
 |_____||___\___/|_| \_|\____\____|(_)_/   \_\___|

       🐟 BettaFish Docker 一键部署
        Powered by LIONCC.AI - 2025
EOF
echo -e "${NC}"

# 日志函数
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_step() { echo -e "\n${CYAN}${BOLD}▶ $1${NC}\n"; }

# 进度条函数
progress_bar() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))

    printf "\r${CYAN}[${NC}"
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "${CYAN}]${NC} ${BOLD}%3d%%${NC}" $percentage
}

# 旋转动画
spinner() {
    local pid=$1
    local message=$2
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    while kill -0 $pid 2>/dev/null; do
        local idx=$((i % 10))
        printf "\r${CYAN}${spinstr:$idx:1}${NC} $message"
        sleep 0.1
        i=$((i + 1))
    done
    printf "\r${GREEN}✓${NC} $message\n"
}

# 检测命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Docker 命令包装器
docker_cmd() {
    if docker "$@" 2>/dev/null; then
        return 0
    elif sudo docker "$@" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# ================================
# 离线包管理功能
# ================================

# 脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OFFLINE_DIR="$SCRIPT_DIR/offline-packages"

# 备份和日志目录
BACKUP_DIR="$SCRIPT_DIR/backups"
LOG_DIR="$SCRIPT_DIR/logs"

# 创建备份和日志目录
mkdir -p "$BACKUP_DIR"
mkdir -p "$LOG_DIR"

# 部署日志文件
DEPLOY_LOG_FILE="$LOG_DIR/deploy_$(date +%Y%m%d_%H%M%S).log"

# 日志记录函数（同时输出到终端和文件）
log_to_file() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$DEPLOY_LOG_FILE"
}

# 下载 Docker 离线镜像
download_docker_image() {
    local image_name="$1"
    local tar_name="$2"

    log_info "下载 Docker 镜像: $image_name"

    if docker pull "$image_name"; then
        log_success "镜像下载成功"

        # 保存为 tar 文件
        mkdir -p "$OFFLINE_DIR"
        local tar_path="$OFFLINE_DIR/$tar_name"

        log_info "保存镜像到: $tar_path"
        if docker save "$image_name" -o "$tar_path"; then
            log_success "镜像已保存到离线包"
            echo "  文件: $tar_path"
            echo "  大小: $(du -h "$tar_path" | cut -f1)"
            return 0
        else
            log_error "保存镜像失败"
            return 1
        fi
    else
        log_error "镜像下载失败"
        return 1
    fi
}

# 加载 Docker 离线镜像
load_docker_image() {
    local tar_name="$1"
    local tar_path="$OFFLINE_DIR/$tar_name"

    if [ -f "$tar_path" ]; then
        log_info "从离线包加载镜像..."
        if docker load -i "$tar_path"; then
            log_success "离线镜像加载成功"
            return 0
        else
            log_error "离线镜像加载失败"
            return 1
        fi
    else
        return 1
    fi
}

# 检查并准备 Docker 镜像
prepare_docker_image() {
    local image_name="$1"
    local tar_name="$2"

    # 检查本地是否已有镜像
    if docker images "$image_name" | grep -q "${image_name#*:}"; then
        log_success "本地已有镜像: $image_name"
        return 0
    fi

    # 尝试从离线包加载
    if load_docker_image "$tar_name"; then
        return 0
    fi

    # 尝试在线拉取
    log_info "尝试在线拉取镜像..."
    if timeout 300 docker pull "$image_name" 2>/dev/null; then
        log_success "镜像拉取成功"
        return 0
    else
        log_error "无法获取镜像"
        return 1
    fi
}

# ================================
# 输入验证函数
# ================================

# 格式化 API 密钥显示（隐藏中间部分）
# 显示格式: 前缀 + 前6位 + *** + 后6位
format_api_key() {
    local key="$1"

    # 检查密钥是否为空
    if [ -z "$key" ]; then
        echo "***"
        return
    fi

    # 检测并保留前缀
    local prefix=""
    local key_without_prefix="$key"

    if [[ "$key" =~ ^sk- ]]; then
        prefix="sk-"
        key_without_prefix="${key#sk-}"
    elif [[ "$key" =~ ^tvly- ]]; then
        prefix="tvly-"
        key_without_prefix="${key#tvly-}"
    elif [[ "$key" =~ ^pk- ]]; then
        prefix="pk-"
        key_without_prefix="${key#pk-}"
    fi

    local key_length=${#key_without_prefix}

    # 根据密钥长度决定显示方式
    if [ $key_length -le 6 ]; then
        # 太短（<=6），只显示前3位
        echo "${prefix}${key_without_prefix:0:3}***"
    elif [ $key_length -le 15 ]; then
        # 中等长度（7-15），显示前3位和后3位
        local first="${key_without_prefix:0:3}"
        local last="${key_without_prefix: -3}"
        echo "${prefix}${first}***${last}"
    else
        # 正常长度（>15），显示前6位和后6位
        local first="${key_without_prefix:0:6}"
        local last="${key_without_prefix: -6}"
        echo "${prefix}${first}***${last}"
    fi
}

# 验证 API 密钥格式
validate_api_key() {
    local key="$1"
    local key_name="$2"

    # 检查是否为空
    if [ -z "$key" ]; then
        return 1
    fi

    # 检查是否误输入了 URL
    if [[ "$key" =~ ^https?:// ]]; then
        log_error "输入错误: 这是一个 URL，不是 API 密钥"
        echo ""
        echo "  您输入的是: $key"
        echo ""
        echo "  ${YELLOW}正确格式示例:${NC}"
        echo "    • OpenAI:    sk-abc123def456..."
        echo "    • Claude:    sk-ant-api03-abc123..."
        echo "    • DeepSeek:  sk-abc123..."
        echo "    • Tavily:    tvly-abc123..."
        echo ""
        return 1
    fi

    # 检查长度（API 密钥通常较长）
    if [ ${#key} -lt 10 ]; then
        log_warn "API 密钥长度似乎过短（少于 10 个字符）"
        echo ""
        printf "  ${YELLOW}确认这是正确的 $key_name 吗? [y/N]: ${NC}"
        read confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi

    # 检查是否包含空格（API 密钥不应该有空格）
    if [[ "$key" =~ [[:space:]] ]]; then
        log_error "API 密钥不应包含空格"
        return 1
    fi

    return 0
}

# 验证 URL 格式
validate_url() {
    local url="$1"

    # 检查是否为空
    if [ -z "$url" ]; then
        return 1
    fi

    # 检查是否为有效的 URL 格式
    if [[ ! "$url" =~ ^https?://[a-zA-Z0-9.-]+(/.*)?$ ]]; then
        log_error "URL 格式不正确"
        echo ""
        echo "  ${YELLOW}正确格式示例:${NC}"
        echo "    • https://api.openai.com/v1"
        echo "    • https://vibecodingapi.ai/v1"
        echo "    • http://localhost:8080/v1"
        echo ""
        return 1
    fi

    return 0
}

# 安全读取 API 密钥（带验证）
read_api_key() {
    local prompt="$1"
    local key_name="$2"
    local is_required="${3:-true}"
    local result=""

    while true; do
        read -p "$(echo -e ${CYAN}${prompt}${NC})" result

        # 如果不是必填且为空，直接返回
        if [ "$is_required" != "true" ] && [ -z "$result" ]; then
            echo "$result"
            return 0
        fi

        # 验证输入
        if validate_api_key "$result" "$key_name"; then
            echo "$result"
            return 0
        fi

        # 验证失败，重新输入
        log_warn "请重新输入正确的 $key_name"
        echo ""
    done
}

# 安全读取 URL（带验证）
read_url() {
    local prompt="$1"
    local default_value="$2"
    local result=""

    while true; do
        read -p "$(echo -e ${CYAN}${prompt}${NC})" result

        # 使用默认值
        if [ -z "$result" ] && [ -n "$default_value" ]; then
            result="$default_value"
        fi

        # 验证 URL
        if validate_url "$result"; then
            echo "$result"
            return 0
        fi

        # 验证失败，重新输入
        log_warn "请重新输入正确的 URL"
        echo ""
    done
}

# ================================
# 初始化部署日志
# ================================
echo "=====================================" >> "$DEPLOY_LOG_FILE"
echo "BettaFish 部署日志" >> "$DEPLOY_LOG_FILE"
echo "开始时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$DEPLOY_LOG_FILE"
echo "=====================================" >> "$DEPLOY_LOG_FILE"

# ================================
# 步骤 1: 环境检测与依赖安装
# ================================
log_step "步骤 1/7: 环境检测与依赖安装"
log_to_file "步骤 1: 环境检测与依赖安装"

echo ""
log_info "开始环境检测..."
log_to_file "开始环境检测"
echo ""

# 检测操作系统
detect_os() {
    case "$(uname -s)" in
        Darwin*) echo "macOS" ;;
        Linux*)
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                echo "$NAME"
            else
                echo "Linux"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*) echo "Windows" ;;
        *) echo "Unknown" ;;
    esac
}

OS_TYPE=$(detect_os)
echo "  📱 操作系统: $OS_TYPE"

# Windows 特殊处理
if [[ "$OS_TYPE" == "Windows" ]]; then
    log_warn "检测到 Windows 系统 (Git Bash 环境)"
    echo ""
    echo -e "${CYAN}Windows 部署要求:${NC}"
    echo "  ✓ 必须已安装 Docker Desktop for Windows"
    echo "  ✓ Docker Desktop 必须处于运行状态"
    echo "  ✓ 建议使用 Git Bash 运行此脚本"
    echo ""

    # 检查 Docker Desktop 是否运行
    if ! docker ps >/dev/null 2>&1; then
        log_error "Docker Desktop 未运行或未安装"
        echo ""
        echo "请按以下步骤操作："
        echo "  1. 从官网下载: https://www.docker.com/products/docker-desktop"
        echo "  2. 安装并启动 Docker Desktop"
        echo "  3. 等待 Docker Desktop 完全启动（托盘图标显示绿色）"
        echo "  4. 重新运行此脚本"
        echo ""
        exit 1
    fi

    log_success "Docker Desktop 运行正常"
    echo ""
    log_info "Windows 环境注意事项："
    echo "  • 某些 Linux 特性（sudo、systemctl）将自动跳过"
    echo "  • Docker 镜像加速需在 Docker Desktop 设置中手动配置"
    echo "  • 脚本将使用 Windows 兼容的命令进行部署"
    echo ""

    printf "${YELLOW}是否继续部署? [Y/n]: ${NC}"
    read CONTINUE_WINDOWS
    CONTINUE_WINDOWS=${CONTINUE_WINDOWS:-Y}

    if [[ ! "$CONTINUE_WINDOWS" =~ ^[Yy]$|^$ ]]; then
        log_info "已取消部署"
        exit 0
    fi
    echo ""
fi

# 检测架构
ARCH=$(uname -m)
echo "  💻 系统架构: $ARCH"

# 检查网络连接
echo "  🌐 网络连接: 检测中..."

NETWORK_OK=false
NETWORK_ERRORS=()

# 测试常用网站的连通性
test_network() {
    local test_urls=(
        "www.google.com"
        "github.com"
        "registry.hub.docker.com"
    )

    local success_count=0

    for url in "${test_urls[@]}"; do
        if ping -c 1 -W 2 "$url" >/dev/null 2>&1 || curl -s --max-time 3 --head "https://$url" >/dev/null 2>&1; then
            success_count=$((success_count + 1))
            break  # 只要有一个成功就认为网络正常
        else
            NETWORK_ERRORS+=("$url")
        fi
    done

    if [ $success_count -gt 0 ]; then
        return 0
    else
        return 1
    fi
}

if test_network; then
    echo -e "\r  🌐 网络连接: ${GREEN}✓ 正常${NC}                    "
    NETWORK_OK=true
else
    log_error "网络连接异常"
    echo ""
    log_warn "无法连接到以下网站:"
    for url in "${NETWORK_ERRORS[@]}"; do
        echo "  ✗ $url"
    done
    echo ""
    log_info "请检查:"
    echo "  1. 网络连接是否正常"
    echo "  2. 是否需要配置代理"
    echo "  3. 防火墙是否阻止了连接"
    echo ""

    read -p "$(echo -e ${YELLOW}是否继续部署（可能会失败）? [y/N]: ${NC})" CONTINUE_DEPLOY
    CONTINUE_DEPLOY=${CONTINUE_DEPLOY:-N}

    if [[ ! "$CONTINUE_DEPLOY" =~ ^[Yy]$ ]]; then
        log_info "已取消部署"
        exit 1
    else
        log_warn "继续部署，但可能会因网络问题失败"
        echo ""
    fi
fi

# 检测是否在国内网络环境
echo "  🗺️  网络环境: 检测中..."
CN_NETWORK=false

# 尝试访问国内镜像源测试
if curl -s --max-time 2 --head "https://mirrors.aliyun.com" >/dev/null 2>&1 || \
   curl -s --max-time 2 --head "https://mirrors.tuna.tsinghua.edu.cn" >/dev/null 2>&1; then
    CN_NETWORK=true
    echo -e "\r  🗺️  网络环境: ${CYAN}国内${NC}                    "
    export USE_CHINA_MIRROR=true  # 国内环境默认启用镜像
else
    echo -e "\r  🗺️  网络环境: ${BLUE}国际${NC}                    "
fi

# 检查必要工具
echo "  🔧 必要工具: 检测中..."

MISSING_TOOLS=()

# 检查 curl
if ! command_exists curl; then
    MISSING_TOOLS+=("curl")
fi

# 检查 git（可选，但推荐）
GIT_INSTALLED=true
if ! command_exists git; then
    GIT_INSTALLED=false
fi

# 如果有缺失的工具，尝试自动安装
if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo -e "\r  🔧 必要工具: ${RED}✗ 缺失 ${MISSING_TOOLS[*]}${NC}"
    echo ""

    if [[ "$OS_TYPE" == "macOS" ]]; then
        log_info "macOS 通常已包含这些工具，如果缺失请安装 Xcode Command Line Tools"
        log_info "运行: xcode-select --install"
    elif [[ "$OS_TYPE" =~ "Ubuntu" ]] || [[ "$OS_TYPE" =~ "Debian" ]]; then
        log_info "尝试自动安装缺失工具..."
        for tool in "${MISSING_TOOLS[@]}"; do
            log_info "安装 $tool..."
            sudo apt-get update -qq && sudo apt-get install -y $tool
        done
    elif [[ "$OS_TYPE" =~ "CentOS" ]] || [[ "$OS_TYPE" =~ "Rocky" ]] || [[ "$OS_TYPE" =~ "Red Hat" ]]; then
        log_info "尝试自动安装缺失工具..."
        for tool in "${MISSING_TOOLS[@]}"; do
            log_info "安装 $tool..."
            sudo yum install -y $tool || sudo dnf install -y $tool
        done
    fi
    echo ""
else
    echo -e "\r  🔧 必要工具: ${GREEN}✓ 已安装${NC}                    "
fi

# 检查 Docker
echo "  🐳 Docker:   检测中..."
DOCKER_INSTALLED=false
if command_exists docker; then
    DOCKER_VERSION=$(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    echo -e "\r  🐳 Docker:   ${GREEN}✓ 已安装 (v$DOCKER_VERSION)${NC}                    "
    DOCKER_INSTALLED=true

    # 检查 Docker 版本
    DOCKER_MAJOR=$(echo $DOCKER_VERSION | cut -d. -f1)
    DOCKER_MINOR=$(echo $DOCKER_VERSION | cut -d. -f2)

    if [ "$DOCKER_MAJOR" -lt 20 ] || ([ "$DOCKER_MAJOR" -eq 20 ] && [ "$DOCKER_MINOR" -lt 10 ]); then
        log_warn "Docker 版本较低，建议升级到 20.10 或更高版本"
    fi
else
    echo -e "\r  🐳 Docker:   ${YELLOW}✗ 未安装${NC}                    "
    DOCKER_INSTALLED=false
fi

# 检查 Homebrew (仅 macOS)
HOMEBREW_INSTALLED=false
if [[ "$OS_TYPE" == "macOS" ]]; then
    echo "  🍺 Homebrew: 检测中..."
    if command_exists brew; then
        BREW_VERSION=$(brew --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
        echo -e "\r  🍺 Homebrew: ${GREEN}✓ 已安装 (v$BREW_VERSION)${NC}                    "
        HOMEBREW_INSTALLED=true
    else
        echo -e "\r  🍺 Homebrew: ${YELLOW}✗ 未安装${NC}                    "
        HOMEBREW_INSTALLED=false
    fi
fi

# 显示环境检测汇总
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
log_info "环境检测完成，结果汇总："
echo ""
echo "  系统信息:"
echo "    • 操作系统: $OS_TYPE"
echo "    • 架构: $ARCH"
echo ""
echo "  网络状态:"
if [ "$NETWORK_OK" = true ]; then
    echo -e "    • 连接: ${GREEN}✓ 正常${NC}"
else
    echo -e "    • 连接: ${RED}✗ 异常${NC}"
fi
if [ "$CN_NETWORK" = true ]; then
    echo "    • 环境: 国内网络 (将使用镜像加速)"
else
    echo "    • 环境: 国际网络"
fi
echo ""
echo "  依赖检查:"
if [ ${#MISSING_TOOLS[@]} -eq 0 ]; then
    echo -e "    • 必要工具: ${GREEN}✓ curl, wget${NC}"
else
    echo -e "    • 必要工具: ${RED}✗ 缺失 ${MISSING_TOOLS[*]}${NC}"
fi
if [ "$GIT_INSTALLED" = true ]; then
    echo -e "    • Git: ${GREEN}✓ 已安装${NC}"
else
    echo -e "    • Git: ${YELLOW}○ 未安装 (可选)${NC}"
fi
if [[ "$OS_TYPE" == "macOS" ]]; then
    if [ "$HOMEBREW_INSTALLED" = true ]; then
        echo -e "    • Homebrew: ${GREEN}✓ 已安装${NC}"
    else
        echo -e "    • Homebrew: ${YELLOW}✗ 需要安装${NC}"
    fi
fi
if [ "$DOCKER_INSTALLED" = true ]; then
    echo -e "    • Docker: ${GREEN}✓ 已安装 (v$DOCKER_VERSION)${NC}"
else
    echo -e "    • Docker: ${YELLOW}✗ 需要安装${NC}"
fi
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 开始安装缺失的依赖
if [ "$DOCKER_INSTALLED" = false ]; then
    log_warn "Docker 未安装，准备自动安装..."
    echo ""

    # 自动安装 Docker
    if [[ "$OS_TYPE" == "macOS" ]]; then
        log_info "macOS 系统，尝试安装 Docker..."
        echo ""

        # 检查 Homebrew
        if command_exists brew; then
            log_success "检测到 Homebrew"
            log_info "开始安装 Docker Desktop..."
            echo ""

            if brew install --cask docker; then
                log_success "Docker Desktop 安装完成"
                echo ""
                log_info "正在自动启动 Docker Desktop..."
                echo ""

                # 尝试启动 Docker Desktop（支持多种路径）
                DOCKER_STARTED=false
                if [ -d "/Applications/Docker.app" ]; then
                    open -g /Applications/Docker.app 2>/dev/null && DOCKER_STARTED=true
                elif [ -d "$HOME/Applications/Docker.app" ]; then
                    open -g "$HOME/Applications/Docker.app" 2>/dev/null && DOCKER_STARTED=true
                fi

                if [ "$DOCKER_STARTED" = true ]; then
                    log_success "Docker Desktop 已启动"
                else
                    log_warn "Docker.app 启动失败，尝试后台启动 Docker 守护进程..."
                fi

                echo ""
                log_info "等待 Docker 守护进程就绪..."
                echo ""
                echo "  检测方式: 监控 Docker socket 和 docker ps 命令"
                echo "  超时时间: 120 秒"
                echo "  检测间隔: 3 秒"
                echo ""

                # 等待 Docker 守护进程启动（检查 Docker socket 和 docker ps）
                WAIT_COUNT=0
                MAX_WAIT=40  # 40 * 3 = 120 秒
                DOCKER_READY=false

                printf "  进度: ["
                while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
                    # 检查 Docker socket 是否存在（Docker Desktop 启动的关键指标）
                    if [ -S "/var/run/docker.sock" ] && docker ps >/dev/null 2>&1; then
                        DOCKER_READY=true
                        break
                    fi

                    # 显示进度点
                    printf "▓"
                    sleep 3
                    WAIT_COUNT=$((WAIT_COUNT + 1))
                done
                printf "] "

                if [ "$DOCKER_READY" = true ]; then
                    echo ""
                    echo ""
                    log_success "Docker 守护进程已就绪！"
                    echo ""
                    log_info "Docker 信息:"
                    docker version --format '  • 版本: {{.Server.Version}}'
                    docker info --format '  • 架构: {{.Architecture}}'
                    docker info --format '  • 操作系统: {{.OperatingSystem}}'
                    echo ""
                else
                    echo ""
                    echo ""
                    log_error "Docker 守护进程启动超时（等待 120 秒）"
                    echo ""
                    log_warn "检测到 Docker Desktop 可能需要首次配置"
                    echo ""
                    echo "  ${CYAN}解决方案 1 - 手动启动 Docker Desktop（推荐用于本地开发）:${NC}"
                    echo "    1. 在 Applications 中找到 Docker 并打开"
                    echo "    2. 接受服务协议 (Service Agreement)"
                    echo "    3. 授权 Docker 访问系统（输入密码）"
                    echo "    4. 等待状态栏显示 🐋 图标"
                    echo "    5. 重新运行: ${CYAN}bash docker-deploy.sh${NC}"
                    echo ""
                    echo "  ${CYAN}解决方案 2 - 使用 Colima（推荐用于 CI/测试环境）:${NC}"
                    echo "    Colima 是轻量级 Docker 运行时，无需 GUI，完全自动化"
                    echo ""
                    printf "    ${YELLOW}是否安装 Colima 替代 Docker Desktop? [Y/n] (回车默认 Y): ${NC}"
                    read INSTALL_COLIMA
                    INSTALL_COLIMA=${INSTALL_COLIMA:-Y}

                    if [[ "$INSTALL_COLIMA" =~ ^[Yy]$|^$ ]]; then
                        echo ""
                        log_step "正在安装 Colima..."
                        echo ""

                        # 安装 Colima 和 Docker CLI
                        log_info "执行命令: brew install colima docker"
                        echo ""
                        if brew install colima docker 2>&1 | tee /tmp/colima_install.log; then
                            echo ""
                            log_success "Colima 安装完成"
                            echo ""
                            log_info "启动 Colima..."
                            echo ""

                            # 启动 Colima（自动配置）
                            if colima start --cpu 2 --memory 4 --disk 50 2>&1 | tee /tmp/colima_start.log; then
                                echo ""
                                log_success "Colima 启动成功！"
                                echo ""

                                # 验证 Docker 可用
                                if docker ps >/dev/null 2>&1; then
                                    log_success "Docker 服务已就绪（Colima 运行时）"
                                    echo ""
                                    log_info "Docker 信息:"
                                    docker version --format '  • 版本: {{.Server.Version}}'
                                    docker info --format '  • 运行时: Colima'
                                    docker info --format '  • 架构: {{.Architecture}}'
                                    echo ""
                                    # 继续部署流程
                                    DOCKER_READY=true
                                else
                                    log_error "Colima 启动后 Docker 仍不可用"
                                    exit 1
                                fi
                            else
                                log_error "Colima 启动失败"
                                log_info "请查看日志: cat /tmp/colima_start.log"
                                exit 1
                            fi
                        else
                            log_error "Colima 安装失败"
                            log_info "请查看日志: cat /tmp/colima_install.log"
                            exit 1
                        fi
                    else
                        echo ""
                        log_info "已取消 Colima 安装"
                        echo ""
                        log_warn "请手动配置 Docker Desktop 后重新运行脚本"
                        echo ""
                        exit 1
                    fi
                fi

                # 只有 Docker 真正就绪后才继续
                if [ "$DOCKER_READY" != true ]; then
                    log_error "Docker 未就绪，退出部署"
                    exit 1
                fi
            else
                log_error "Docker 安装失败"
                log_info "请检查网络连接后重试"
                exit 1
            fi
        else
            log_warn "未检测到 Homebrew"
            echo ""
            log_info "Homebrew 是 macOS 最流行的包管理器，可以自动安装 Docker"
            echo ""

            # 询问是否自动安装 Homebrew（回车默认 Y）
            echo ""
            printf "${YELLOW}是否自动安装 Homebrew? [Y/n] (回车默认 Y): ${NC}"
            read INSTALL_BREW
            INSTALL_BREW=${INSTALL_BREW:-Y}

            if [[ "$INSTALL_BREW" =~ ^[Yy]$|^$ ]]; then
                echo ""
                log_step "正在安装 Homebrew..."
                echo ""

                # 如果在国内网络环境，使用国内镜像安装
                if [[ "$USE_CHINA_MIRROR" == "true" ]]; then
                    log_info "检测到国内网络环境，使用中科大镜像加速安装"
                    echo ""

                    export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
                    export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
                    export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"

                    log_info "执行命令: /bin/bash -c \"\$(curl -fsSL https://mirrors.ustc.edu.cn/misc/brew-install.sh)\""
                    echo ""
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo "                     Homebrew 安装输出"
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo ""

                    if /bin/bash -c "$(curl -fsSL https://mirrors.ustc.edu.cn/misc/brew-install.sh)" 2>&1 | tee /tmp/brew_install.log; then
                        echo ""
                        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        log_success "Homebrew 安装完成（使用国内镜像）"
                    else
                        echo ""
                        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        log_warn "国内镜像安装失败，尝试使用官方源..."
                        echo ""

                        log_info "执行命令: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
                        echo ""

                        if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" 2>&1 | tee /tmp/brew_install.log; then
                            echo ""
                            log_success "Homebrew 安装完成"
                        else
                            echo ""
                            log_error "Homebrew 安装失败"
                            log_info "查看完整日志: cat /tmp/brew_install.log"
                            exit 1
                        fi
                    fi
                else
                    log_info "使用官方源安装 Homebrew"
                    echo ""
                    log_info "执行命令: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
                    echo ""
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo "                     Homebrew 安装输出"
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo ""

                    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" 2>&1 | tee /tmp/brew_install.log; then
                        echo ""
                        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        log_success "Homebrew 安装完成"
                    else
                        echo ""
                        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        log_error "Homebrew 安装失败"
                        log_info "查看完整日志: cat /tmp/brew_install.log"
                        exit 1
                    fi
                fi

                echo ""

                # 配置 Homebrew 环境变量
                log_info "配置 Homebrew 环境变量..."

                # 根据架构确定 Homebrew 路径
                if [[ "$ARCH" == "arm64" ]]; then
                    BREW_PREFIX="/opt/homebrew"
                else
                    BREW_PREFIX="/usr/local"
                fi

                # 检查 brew 是否存在
                if [ -x "$BREW_PREFIX/bin/brew" ]; then
                    log_success "找到 Homebrew: $BREW_PREFIX/bin/brew"
                    eval "$($BREW_PREFIX/bin/brew shellenv)"
                    export PATH="$BREW_PREFIX/bin:$PATH"
                else
                    log_error "Homebrew 安装后未找到可执行文件"
                    log_info "预期位置: $BREW_PREFIX/bin/brew"
                    log_info "请检查安装日志: /tmp/brew_install.log"
                    exit 1
                fi

                # 如果使用国内镜像，持久化配置
                if [[ "$USE_CHINA_MIRROR" == "true" ]]; then
                    log_info "配置 Homebrew 国内镜像（持久化）..."

                    SHELL_RC=""
                    if [[ -f "$HOME/.zshrc" ]]; then
                        SHELL_RC="$HOME/.zshrc"
                    elif [[ -f "$HOME/.bashrc" ]]; then
                        SHELL_RC="$HOME/.bash_profile"
                    fi

                    if [[ -n "$SHELL_RC" ]]; then
                        if ! grep -q "HOMEBREW_BOTTLE_DOMAIN" "$SHELL_RC"; then
                            cat >> "$SHELL_RC" << 'EOF'

# Homebrew 国内镜像加速
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
EOF
                            log_success "Homebrew 镜像配置已添加到 $SHELL_RC"
                        fi
                    fi
                fi

                if true; then

                    log_info "继续安装 Docker Desktop..."
                    echo ""

                    if brew install --cask docker; then
                        log_success "Docker Desktop 安装完成"
                        echo ""
                        log_info "正在自动启动 Docker Desktop..."
                        echo ""

                        # 尝试启动 Docker Desktop（支持多种路径）
                        DOCKER_STARTED=false
                        if [ -d "/Applications/Docker.app" ]; then
                            open -g /Applications/Docker.app 2>/dev/null && DOCKER_STARTED=true
                        elif [ -d "$HOME/Applications/Docker.app" ]; then
                            open -g "$HOME/Applications/Docker.app" 2>/dev/null && DOCKER_STARTED=true
                        fi

                        if [ "$DOCKER_STARTED" = true ]; then
                            log_success "Docker Desktop 已启动"
                        else
                            log_warn "Docker.app 启动失败，尝试后台启动 Docker 守护进程..."
                        fi

                        echo ""
                        log_info "等待 Docker 守护进程就绪..."
                        echo ""
                        echo "  检测方式: 监控 Docker socket 和 docker ps 命令"
                        echo "  超时时间: 120 秒"
                        echo "  检测间隔: 3 秒"
                        echo ""

                        # 等待 Docker 守护进程启动（检查 Docker socket 和 docker ps）
                        WAIT_COUNT=0
                        MAX_WAIT=40  # 40 * 3 = 120 秒
                        DOCKER_READY=false

                        printf "  进度: ["
                        while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
                            # 检查 Docker socket 是否存在（Docker Desktop 启动的关键指标）
                            if [ -S "/var/run/docker.sock" ] && docker ps >/dev/null 2>&1; then
                                DOCKER_READY=true
                                break
                            fi

                            # 显示进度点
                            printf "▓"
                            sleep 3
                            WAIT_COUNT=$((WAIT_COUNT + 1))
                        done
                        printf "] "

                        if [ "$DOCKER_READY" = true ]; then
                            echo ""
                            echo ""
                            log_success "Docker 守护进程已就绪！"
                            echo ""
                            log_info "Docker 信息:"
                            docker version --format '  • 版本: {{.Server.Version}}'
                            docker info --format '  • 架构: {{.Architecture}}'
                            docker info --format '  • 操作系统: {{.OperatingSystem}}'
                            echo ""
                        else
                            echo ""
                            echo ""
                            log_error "Docker 守护进程启动超时（等待 120 秒）"
                            echo ""
                            log_warn "检测到 Docker Desktop 可能需要首次配置"
                            echo ""
                            echo "  ${CYAN}解决方案 1 - 手动启动 Docker Desktop（推荐用于本地开发）:${NC}"
                            echo "    1. 在 Applications 中找到 Docker 并打开"
                            echo "    2. 接受服务协议 (Service Agreement)"
                            echo "    3. 授权 Docker 访问系统（输入密码）"
                            echo "    4. 等待状态栏显示 🐋 图标"
                            echo "    5. 重新运行: ${CYAN}bash docker-deploy.sh${NC}"
                            echo ""
                            echo "  ${CYAN}解决方案 2 - 使用 Colima（推荐用于 CI/测试环境）:${NC}"
                            echo "    Colima 是轻量级 Docker 运行时，无需 GUI，完全自动化"
                            echo ""
                            printf "    ${YELLOW}是否安装 Colima 替代 Docker Desktop? [Y/n] (回车默认 Y): ${NC}"
                            read INSTALL_COLIMA
                            INSTALL_COLIMA=${INSTALL_COLIMA:-Y}

                            if [[ "$INSTALL_COLIMA" =~ ^[Yy]$|^$ ]]; then
                                echo ""
                                log_step "正在安装 Colima..."
                                echo ""

                                # 安装 Colima 和 Docker CLI
                                log_info "执行命令: brew install colima docker"
                                echo ""
                                if brew install colima docker 2>&1 | tee /tmp/colima_install.log; then
                                    echo ""
                                    log_success "Colima 安装完成"
                                    echo ""
                                    log_info "启动 Colima..."
                                    echo ""

                                    # 启动 Colima（自动配置）
                                    if colima start --cpu 2 --memory 4 --disk 50 2>&1 | tee /tmp/colima_start.log; then
                                        echo ""
                                        log_success "Colima 启动成功！"
                                        echo ""

                                        # 验证 Docker 可用
                                        if docker ps >/dev/null 2>&1; then
                                            log_success "Docker 服务已就绪（Colima 运行时）"
                                            echo ""
                                            log_info "Docker 信息:"
                                            docker version --format '  • 版本: {{.Server.Version}}'
                                            docker info --format '  • 运行时: Colima'
                                            docker info --format '  • 架构: {{.Architecture}}'
                                            echo ""
                                            # 继续部署流程
                                            DOCKER_READY=true
                                        else
                                            log_error "Colima 启动后 Docker 仍不可用"
                                            exit 1
                                        fi
                                    else
                                        log_error "Colima 启动失败"
                                        log_info "请查看日志: cat /tmp/colima_start.log"
                                        exit 1
                                    fi
                                else
                                    log_error "Colima 安装失败"
                                    log_info "请查看日志: cat /tmp/colima_install.log"
                                    exit 1
                                fi
                            else
                                echo ""
                                log_info "已取消 Colima 安装"
                                echo ""
                                log_warn "请手动配置 Docker Desktop 后重新运行脚本"
                                echo ""
                                exit 1
                            fi
                        fi

                        # 只有 Docker 真正就绪后才继续
                        if [ "$DOCKER_READY" != true ]; then
                            log_error "Docker 未就绪，退出部署"
                            exit 1
                        fi
                    else
                        log_error "Docker 安装失败"
                        exit 1
                    fi
                else
                    log_error "Homebrew 安装失败"
                    echo ""
                    log_info "请手动安装 Docker Desktop:"
                    echo "  访问: https://www.docker.com/products/docker-desktop"
                    echo "  下载 macOS 版本（支持 M1/M2/M3）"
                    exit 1
                fi
            else
                log_info "已取消自动安装"
                echo ""
                log_info "请手动安装 Docker:"
                echo ""
                echo "  方式1: 先安装 Homebrew，再运行此脚本"
                echo "    /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
                echo ""
                echo "  方式2: 手动下载 Docker Desktop"
                echo "    访问: https://www.docker.com/products/docker-desktop"
                echo ""
                exit 1
            fi
        fi

    elif [[ "$OS_TYPE" =~ "Ubuntu" ]] || [[ "$OS_TYPE" =~ "Debian" ]]; then
        log_info "检测到 Ubuntu/Debian 系统，使用官方脚本安装..."
        if curl -fsSL https://get.docker.com | sudo sh; then
            log_success "Docker 安装完成"
            log_info "启动 Docker 服务..."
            sudo systemctl start docker
            sudo systemctl enable docker
            log_success "Docker 服务已启动"

            # 添加用户到 docker 组
            log_info "将当前用户添加到 docker 组..."
            sudo usermod -aG docker $USER
            log_warn "需要重新登录才能生效，或运行: newgrp docker"
            echo ""
            log_info "请运行以下命令后重新执行脚本:"
            echo "  newgrp docker"
            echo "  bash docker-deploy.sh"
            echo ""
            exit 0
        else
            log_error "Docker 安装失败"
            exit 1
        fi

    elif [[ "$OS_TYPE" =~ "CentOS" ]] || [[ "$OS_TYPE" =~ "Rocky" ]] || [[ "$OS_TYPE" =~ "Red Hat" ]]; then
        log_info "检测到 CentOS/RHEL/Rocky 系统，使用官方脚本安装..."
        if curl -fsSL https://get.docker.com | sudo sh; then
            log_success "Docker 安装完成"
            log_info "启动 Docker 服务..."
            sudo systemctl start docker
            sudo systemctl enable docker
            log_success "Docker 服务已启动"

            # 添加用户到 docker 组
            log_info "将当前用户添加到 docker 组..."
            sudo usermod -aG docker $USER
            log_warn "需要重新登录才能生效，或运行: newgrp docker"
            echo ""
            log_info "请运行以下命令后重新执行脚本:"
            echo "  newgrp docker"
            echo "  bash docker-deploy.sh"
            echo ""
            exit 0
        else
            log_error "Docker 安装失败"
            exit 1
        fi

    else
        log_error "暂不支持自动安装 Docker"
        echo ""
        log_info "请访问 https://docs.docker.com/get-docker/ 手动安装"
        echo ""
        exit 1
    fi
fi

# 检查 Docker 运行状态
log_info "检查 Docker 服务状态..."
if docker ps >/dev/null 2>&1; then
    log_success "Docker 服务运行正常"
elif sudo docker ps >/dev/null 2>&1; then
    log_success "Docker 服务运行正常 (需要 sudo 权限)"
    log_warn "建议将当前用户加入 docker 组: sudo usermod -aG docker \$USER"
else
    log_error "Docker 服务未运行"
    echo ""

    if [[ "$OS_TYPE" == "macOS" ]]; then
        log_info "macOS 需要启动 Docker Desktop"
        echo ""
        log_warn "正在尝试自动启动 Docker Desktop..."

        # 尝试自动启动 Docker Desktop
        if [ -d "/Applications/Docker.app" ]; then
            open -a Docker
            log_info "已发送启动命令，等待 Docker 启动..."
            echo ""
            log_warn "请注意："
            echo "  1. Docker Desktop 首次启动可能需要 2-3 分钟"
            echo "  2. 需要接受 Docker 的服务协议"
            echo "  3. 可能需要输入系统密码授权"
            echo ""

            # 等待 Docker 启动
            log_info "等待 Docker 服务就绪（最多等待 2 分钟）..."
            WAIT_COUNT=0
            while [ $WAIT_COUNT -lt 24 ]; do
                if docker ps >/dev/null 2>&1; then
                    log_success "Docker 服务已启动！"
                    break
                fi
                printf "."
                sleep 5
                WAIT_COUNT=$((WAIT_COUNT + 1))
            done
            echo ""

            if ! docker ps >/dev/null 2>&1; then
                log_error "Docker 启动超时"
                echo ""
                log_info "请手动检查："
                echo "  1. Docker Desktop 是否已打开"
                echo "  2. 状态栏是否显示 Docker 图标"
                echo "  3. 是否需要接受服务协议或授权"
                echo ""
                log_info "确认 Docker 启动后，重新运行此脚本"
                exit 1
            fi
        else
            log_error "未找到 Docker Desktop 应用"
            echo ""
            log_info "请先安装 Docker Desktop:"
            echo "  brew install --cask docker"
            echo "  或访问: https://www.docker.com/products/docker-desktop"
            exit 1
        fi

    elif [[ "$OS_TYPE" == "Windows" ]]; then
        # Windows 使用 Docker Desktop，无需手动启动
        log_info "Windows 环境，Docker Desktop 自动管理服务"
    else
        # Linux 需要 systemctl 启动服务
        log_info "Linux 需要启动 Docker 服务"
        echo ""
        log_info "尝试自动启动 Docker 服务..."

        if sudo systemctl start docker 2>/dev/null; then
            log_success "Docker 服务启动成功"
            sudo systemctl enable docker
        else
            log_error "Docker 服务启动失败"
            echo ""
            log_info "请手动启动: sudo systemctl start docker"
            exit 1
        fi
    fi
fi

# ================================
# 配置 Docker 镜像加速（国内网络）- 仅验证，不自动配置
# ================================
if [ "$CN_NETWORK" = true ]; then
    echo ""
    log_info "检测到国内网络环境..."

    if [[ "$OS_TYPE" == "macOS" ]]; then
        # macOS Docker Desktop 配置
        DOCKER_CONFIG_FILE="$HOME/.docker/daemon.json"

        # 检查配置文件是否存在
        if [ ! -f "$DOCKER_CONFIG_FILE" ]; then
            log_info "创建 Docker 配置文件..."
            mkdir -p "$HOME/.docker"
            cat > "$DOCKER_CONFIG_FILE" << 'EOF'
{
  "registry-mirrors": [
    "https://docker.chenby.cn",
    "https://docker.awsl9527.cn",
    "https://dockerproxy.com",
    "https://docker.m.daocloud.io"
  ]
}
EOF
            log_success "Docker 镜像加速配置已创建"
            echo ""
            log_warn "需要重启 Docker Desktop 才能生效"
            echo ""
            echo "  正在重启 Docker Desktop..."

            # 重启 Docker Desktop
            if command -v osascript >/dev/null 2>&1; then
                osascript -e 'quit app "Docker"' 2>/dev/null || true
                sleep 3
                open -a Docker 2>/dev/null || true

                log_info "等待 Docker 重新启动..."
                WAIT_COUNT=0
                while [ $WAIT_COUNT -lt 30 ]; do
                    if docker ps >/dev/null 2>&1; then
                        log_success "Docker Desktop 已重启"
                        break
                    fi
                    printf "."
                    sleep 2
                    WAIT_COUNT=$((WAIT_COUNT + 1))
                done
                echo ""
            fi
        else
            # 检查是否已配置镜像（仅检测，不自动配置）
            if grep -q "registry-mirrors" "$DOCKER_CONFIG_FILE"; then
                log_success "Docker 镜像加速已配置"
                echo ""
                echo "  配置的镜像源:"
                grep -A 5 "registry-mirrors" "$DOCKER_CONFIG_FILE" | head -7
                echo ""
            else
                log_info "未检测到 Docker 镜像加速配置"
                log_info "将通过脚本的镜像源选择功能来加速下载"
                echo ""
            fi
        fi
    elif [[ "$OS_TYPE" == "Windows" ]]; then
        log_info "Windows 环境，将通过镜像源选择功能加速下载"
        echo ""
    else
        log_info "Linux 环境，将通过镜像源选择功能加速下载"
        echo ""
    fi
else
    log_info "海外网络环境，将使用官方镜像源"
    echo ""
fi

# ================================
# 测试 Docker 镜像拉取能力
# ================================
echo ""
log_info "测试 Docker 镜像源可用性..."

DOCKER_IMAGE_OK=false

# 使用离线包管理功能检查镜像
if prepare_docker_image "python:3.11-slim" "python-3.11-slim.tar"; then
        log_success "python:3.11-slim 镜像就绪"
        DOCKER_IMAGE_OK=true
    else
        log_warn "无法获取 python:3.11-slim 镜像"
        DOCKER_IMAGE_OK=false

        echo ""
        log_warn "当前镜像源可能不可用，建议使用备选方案："
        echo ""
        echo "  ${CYAN}方案 1:${NC} 导入本地离线包（推荐）"
        echo "    • 从已下载的离线包导入镜像"
        echo "    • 不需要网络连接"
        echo "    • 位置: $OFFLINE_DIR"
        echo ""
        echo "  ${CYAN}方案 2:${NC} 下载离线镜像包"
        echo "    • 使用下载脚本获取离线包"
        echo "    • 自动保存到本地"
        echo "    • 下次可直接使用"
        echo ""
        echo "  ${CYAN}方案 3:${NC} 稍后重试 Docker 部署"
        echo "    • 等待镜像源恢复"
        echo "    • 使用完整容器化方案"
        echo ""

        printf "${YELLOW}请选择方案 [1/2/3]: ${NC}"
        read DEPLOY_CHOICE

        if [[ "$DEPLOY_CHOICE" == "1" ]]; then
            log_info "从本地离线包导入镜像..."
            echo ""

            # 检查离线包是否存在
            if [ ! -d "$OFFLINE_DIR" ] || [ -z "$(ls -A $OFFLINE_DIR/*.tar 2>/dev/null)" ]; then
                log_error "未找到离线包"
                echo ""
                log_info "请先运行下载脚本获取离线包："
                echo ""
                echo "  ${CYAN}./download-offline-packages.sh${NC}"
                echo ""
                log_info "或手动准备离线包到目录："
                echo "  ${CYAN}$OFFLINE_DIR${NC}"
                echo ""
                exit 1
            fi

            # 导入所有离线包
            for tar_file in "$OFFLINE_DIR"/*.tar; do
                if [ -f "$tar_file" ]; then
                    filename=$(basename "$tar_file")
                    log_info "导入: $filename"

                    if docker load -i "$tar_file"; then
                        log_success "$filename 导入成功"
                    else
                        log_error "$filename 导入失败"
                    fi
                fi
            done

            echo ""
            log_success "离线包导入完成"
            echo ""
            log_info "继续 Docker 部署..."
            DOCKER_IMAGE_OK=true

        elif [[ "$DEPLOY_CHOICE" == "2" ]]; then
            log_info "启动离线包下载脚本..."
            echo ""

            # 检查下载脚本是否存在
            if [ -f "$SCRIPT_DIR/download-offline-packages.sh" ]; then
                log_info "运行: ./download-offline-packages.sh"
                echo ""
                bash "$SCRIPT_DIR/download-offline-packages.sh"

                echo ""
                log_info "下载完成后，请重新运行部署脚本："
                echo ""
                echo "  ${CYAN}./docker-deploy.sh${NC}"
                echo ""
                exit 0
            else
                log_error "未找到下载脚本: download-offline-packages.sh"
                echo ""
                log_info "请手动下载镜像："
                echo ""
                echo "  ${CYAN}docker pull python:3.11-slim${NC}"
                echo "  ${CYAN}docker pull postgres:15-alpine${NC}"
                echo ""
                echo "  ${CYAN}mkdir -p $OFFLINE_DIR${NC}"
                echo "  ${CYAN}docker save python:3.11-slim -o $OFFLINE_DIR/python-3.11-slim.tar${NC}"
                echo "  ${CYAN}docker save postgres:15-alpine -o $OFFLINE_DIR/postgres-15-alpine.tar${NC}"
                echo ""
                exit 1
            fi

        else
            log_info "继续 Docker 部署（可能会失败）"
            echo ""
        fi
    fi

progress_bar 1 7
sleep 0.5

# ================================
# 步骤 2: 检查项目源码
# ================================
log_step "步骤 2/7: 检查项目源码"

# 查找 BettaFish 项目目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR=""

# 可能的项目路径
POSSIBLE_PATHS=(
    "$SCRIPT_DIR/BettaFish-main"
    "$SCRIPT_DIR/../BettaFish-main"
    "$SCRIPT_DIR/BettaFish"
    "$SCRIPT_DIR/../BettaFish"
)

log_info "查找 BettaFish 项目目录..."
for path in "${POSSIBLE_PATHS[@]}"; do
    if [ -d "$path" ] && [ -f "$path/Dockerfile" ]; then
        PROJECT_DIR="$path"
        log_success "找到项目目录: $PROJECT_DIR"
        break
    fi
done

if [ -z "$PROJECT_DIR" ]; then
    log_error "未找到 BettaFish 项目源码"
    echo ""
    log_info "请确保项目结构如下："
    echo ""
    echo "  BettaFish-Deployment-Kit/"
    echo "  ├── docker-deploy.sh         (本脚本)"
    echo "  └── BettaFish-main/           (从 GitHub 下载的项目)"
    echo "      ├── Dockerfile"
    echo "      ├── InsightEngine/"
    echo "      ├── MediaEngine/"
    echo "      └── ..."
    echo ""
    log_info "从 GitHub 下载项目:"
    echo ""
    echo "  git clone https://github.com/your-repo/BettaFish.git BettaFish-main"
    echo ""
    exit 1
fi

cd "$PROJECT_DIR"
progress_bar 2 7
sleep 0.5

# ================================
# 步骤 3: 配置 API 密钥
# ================================
log_step "步骤 3/7: 配置 API 密钥"

# 检查是否已有 .env 配置文件
ENV_FILE_PATH="$PROJECT_DIR/.env"
if [ -f "$ENV_FILE_PATH" ]; then
    log_info "检测到已有配置文件"
    echo ""

    # 读取现有配置
    if grep -q "INSIGHT_ENGINE_API_KEY" "$ENV_FILE_PATH"; then
        EXISTING_AGENT_KEY=$(grep "^INSIGHT_ENGINE_API_KEY=" "$ENV_FILE_PATH" | cut -d'=' -f2 | tr -d '\r\n' | tr -d '"' | tr -d "'")
        EXISTING_BASE_URL=$(grep "^INSIGHT_ENGINE_BASE_URL=" "$ENV_FILE_PATH" | cut -d'=' -f2 | tr -d '\r\n' | tr -d '"' | tr -d "'")
        EXISTING_TAVILY_KEY=$(grep "^TAVILY_API_KEY=" "$ENV_FILE_PATH" | cut -d'=' -f2 | tr -d '\r\n' | tr -d '"' | tr -d "'")
        EXISTING_BOCHA_KEY=$(grep "^BOCHA_WEB_SEARCH_API_KEY=" "$ENV_FILE_PATH" | cut -d'=' -f2 | tr -d '\r\n' | tr -d '"' | tr -d "'")

        echo -e "${GREEN}现有配置:${NC}"
        echo -e "  • 主 API 密钥: $(format_api_key "$EXISTING_AGENT_KEY")"
        echo -e "  • Base URL: $EXISTING_BASE_URL"
        echo -e "  • Tavily 密钥: $(format_api_key "$EXISTING_TAVILY_KEY")"

        # Bocha 密钥特殊处理（如果为空显示提示）
        if [ -z "$EXISTING_BOCHA_KEY" ]; then
            echo -e "  • Bocha 密钥: ${YELLOW}(未配置)${NC}"
        else
            echo -e "  • Bocha 密钥: $(format_api_key "$EXISTING_BOCHA_KEY")"
        fi
        echo ""

        printf "${YELLOW}是否使用现有配置? [Y/n] (回车默认 Y): ${NC}"
        read USE_EXISTING
        USE_EXISTING=${USE_EXISTING:-Y}
        echo ""

        if [[ "$USE_EXISTING" =~ ^[Yy]$|^$ ]]; then
            log_success "使用现有配置"
            AGENT_KEY="$EXISTING_AGENT_KEY"
            BASE_URL="$EXISTING_BASE_URL"
            TAVILY_KEY="$EXISTING_TAVILY_KEY"
            BOCHA_KEY="$EXISTING_BOCHA_KEY"

            # 检查是否有空的密钥需要补充
            NEED_SUPPLEMENT=false

            if [ -z "$BOCHA_KEY" ]; then
                NEED_SUPPLEMENT=true
            fi

            # 如果有空的密钥，提示补充
            if [ "$NEED_SUPPLEMENT" = true ]; then
                echo ""
                log_warn "检测到以下密钥未配置，需要补充："

                if [ -z "$BOCHA_KEY" ]; then
                    echo "  • Bocha API 密钥"
                fi
                echo ""

                # 补充 Bocha 密钥
                if [ -z "$BOCHA_KEY" ]; then
                    printf "${YELLOW}请输入 Bocha API 密钥 (可选，直接回车跳过): ${NC}"
                    read BOCHA_KEY
                    BOCHA_KEY=$(echo "$BOCHA_KEY" | tr -d '\r\n' | tr -d '"' | tr -d "'")
                    echo ""

                    if [ -n "$BOCHA_KEY" ]; then
                        log_success "Bocha API 密钥已设置"
                    else
                        log_info "Bocha API 密钥未设置（已跳过）"
                    fi
                fi
            fi

            # 显示最终配置摘要
            echo ""
            echo -e "${GREEN}配置摘要:${NC}"
            echo -e "  • 主 API 密钥: $(format_api_key "$AGENT_KEY")"
            echo -e "  • Base URL: $BASE_URL"
            echo -e "  • Tavily 密钥: $(format_api_key "$TAVILY_KEY")"

            # Bocha 密钥显示
            if [ -z "$BOCHA_KEY" ]; then
                echo -e "  • Bocha 密钥: ${YELLOW}(未配置)${NC}"
            else
                echo -e "  • Bocha 密钥: $(format_api_key "$BOCHA_KEY")"
            fi
            echo ""
            progress_bar 3 7
            sleep 0.5

            # 跳到步骤 4
            SKIP_INPUT=true
        else
            log_info "重新配置 API 密钥"
            echo ""
            SKIP_INPUT=false
        fi
    fi
fi

if [ "$SKIP_INPUT" != "true" ]; then
    echo -e "${BOLD}请输入您的 API 配置信息:${NC}"
    echo -e "${YELLOW}提示: 只需要一个 API 密钥，会自动配置所有 7 个引擎${NC}"
    echo ""
    echo -e "${YELLOW}注意事项:${NC}"
    echo "  • API 密钥格式通常为: sk-xxx... 或 tvly-xxx..."
    echo "  • API 密钥不应包含空格"
    echo "  • Base URL 将使用默认配置"
    echo ""

    # 主 API Key（带验证）
    AGENT_KEY=$(read_api_key "主 API 密钥 [必填]: " "主 API 密钥" "true")

    # Base URL（固定值，不支持修改）
    echo ""
    BASE_URL="https://vibecodingapi.ai/v1"
    echo -e "${CYAN}ℹ️  API Base URL:${NC} ${BLUE}${BASE_URL}${NC}"
    echo -e "${GRAY}   (固定配置，如需修改请在部署后编辑 .env 文件)${NC}"

    # Tavily API Key（带验证）
    echo ""
    TAVILY_KEY=$(read_api_key "Tavily API 密钥 [必填]: " "Tavily API 密钥" "true")

    # Bocha API Key（带验证）
    echo ""
    BOCHA_KEY=$(read_api_key "Bocha API 密钥 [必填]: " "Bocha API 密钥" "true")

    echo ""
    log_success "API 配置收集完成"
    echo ""
    echo -e "${GREEN}配置摘要:${NC}"
    echo -e "  • 主 API 密钥: $(format_api_key "$AGENT_KEY")"
    echo -e "  • Base URL: $BASE_URL"
    echo -e "  • Tavily 密钥: $(format_api_key "$TAVILY_KEY")"
    echo -e "  • Bocha 密钥: $(format_api_key "$BOCHA_KEY")"
    echo ""
    progress_bar 3 7
    sleep 0.5
fi

# ================================
# 步骤 4: 生成环境配置文件
# ================================
log_step "步骤 4/7: 生成环境配置"

ENV_FILE=".env"

# 检查是否需要备份（只有在配置改变时才备份）
NEED_BACKUP=false

# 如果是重新输入配置，需要备份
if [ "$SKIP_INPUT" != "true" ]; then
    NEED_BACKUP=true
elif [ -f "$ENV_FILE" ]; then
    # 检查配置是否改变（比较 Bocha 密钥等可能补充的字段）
    EXISTING_BOCHA_IN_FILE=$(grep "^BOCHA_WEB_SEARCH_API_KEY=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2)
    if [ "$EXISTING_BOCHA_IN_FILE" != "$BOCHA_KEY" ]; then
        NEED_BACKUP=true
    fi
fi

# 备份旧的 .env 文件（仅在需要时）
if [ "$NEED_BACKUP" = true ] && [ -f "$ENV_FILE" ]; then
    BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="$BACKUP_DIR/env_backup_${BACKUP_TIMESTAMP}.env"
    log_info "备份现有配置到: backups/env_backup_${BACKUP_TIMESTAMP}.env"
    cp "$ENV_FILE" "$BACKUP_FILE"
fi

log_info "生成 .env 文件..."

# 安全检查：如果 .env 是目录，先删除
if [ -d "$ENV_FILE" ]; then
    log_warn ".env 是目录而非文件，正在清理..."
    rm -rf "$ENV_FILE"
fi

cat > "$ENV_FILE" << EOF
# ====================== BETTAFISH 服务配置 ======================
HOST=0.0.0.0
PORT=5000

# ====================== 数据库配置 ======================
DB_HOST=db
DB_PORT=5432
DB_USER=bettafish
DB_PASSWORD=bettafish_secure_$(date +%s)
DB_NAME=bettafish
DB_CHARSET=utf8mb4
DB_DIALECT=postgresql

# ======================= LLM 配置 (统一 API Key) =======================
# Insight Engine - 洞察引擎
INSIGHT_ENGINE_API_KEY=${AGENT_KEY}
INSIGHT_ENGINE_BASE_URL=${BASE_URL}
INSIGHT_ENGINE_MODEL_NAME=gpt-4o

# Media Engine - 媒体引擎
MEDIA_ENGINE_API_KEY=${AGENT_KEY}
MEDIA_ENGINE_BASE_URL=${BASE_URL}
MEDIA_ENGINE_MODEL_NAME=gpt-4o

# MindSpider Engine - 爬虫引擎
MINDSPIDER_API_KEY=${AGENT_KEY}
MINDSPIDER_BASE_URL=${BASE_URL}
MINDSPIDER_MODEL_NAME=deepseek-chat

# Query Engine - 查询引擎
QUERY_ENGINE_API_KEY=${AGENT_KEY}
QUERY_ENGINE_BASE_URL=${BASE_URL}
QUERY_ENGINE_MODEL_NAME=gpt-4o

# Report Engine - 报告引擎
REPORT_ENGINE_API_KEY=${AGENT_KEY}
REPORT_ENGINE_BASE_URL=${BASE_URL}
REPORT_ENGINE_MODEL_NAME=gemini-2.5-pro

# Forum Engine - 论坛引擎
FORUM_HOST_API_KEY=${AGENT_KEY}
FORUM_HOST_BASE_URL=${BASE_URL}
FORUM_HOST_MODEL_NAME=gpt-4o

# Keyword Optimizer - 关键词优化引擎
KEYWORD_OPTIMIZER_API_KEY=${AGENT_KEY}
KEYWORD_OPTIMIZER_BASE_URL=${BASE_URL}
KEYWORD_OPTIMIZER_MODEL_NAME=gpt-3.5-turbo

# ================== 网络工具配置 ====================
# Tavily 搜索 API
TAVILY_API_KEY=${TAVILY_KEY}

# Bocha 搜索 API
BOCHA_BASE_URL=https://api.bochaai.com
BOCHA_WEB_SEARCH_API_KEY=${BOCHA_KEY}

# ================== 部署信息 ====================
# 部署时间: $(date '+%Y-%m-%d %H:%M:%S')
# 部署系统: ${OS_TYPE} (${ARCH})
# Docker 版本: ${DOCKER_VERSION}
EOF

log_success ".env 文件生成完成"
log_info "配置了 7 个引擎，统一使用相同 API Key"
progress_bar 4 7
sleep 0.5

# ================================
# 步骤 5: 拉取 Docker 镜像
# ================================
log_step "步骤 5/7: 拉取 Docker 镜像"

cd "$PROJECT_DIR"

# ============== 智能镜像检测 ==============
# 检查是否已存在镜像（支持多种镜像名）
EXISTING_IMAGE=$(docker images -q bettafish:latest 2>/dev/null)
if [ -z "$EXISTING_IMAGE" ]; then
    # 检查 ghcr.io 镜像
    EXISTING_IMAGE=$(docker images -q "ghcr.io/666ghj/bettafish:latest" 2>/dev/null)
fi
if [ -z "$EXISTING_IMAGE" ]; then
    # 检查南京大学镜像
    EXISTING_IMAGE=$(docker images -q "ghcr.nju.edu.cn/666ghj/bettafish:latest" 2>/dev/null)
fi

HAS_EXISTING_IMAGE=false
ARCH_MISMATCH=false

if [ -n "$EXISTING_IMAGE" ]; then
    HAS_EXISTING_IMAGE=true
    log_info "检测到已存在 BettaFish 镜像"

    # 检查镜像架构
    IMAGE_ARCH=$(docker inspect --format='{{.Architecture}}' "$EXISTING_IMAGE" 2>/dev/null || echo "未知")
    IMAGE_CREATED=$(docker inspect --format='{{.Created}}' "$EXISTING_IMAGE" 2>/dev/null)

    # 跨平台兼容的日期格式化
    if [[ "$OSTYPE" == "darwin"* ]]; then
        IMAGE_DATE=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$(echo $IMAGE_CREATED | cut -d'.' -f1)" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "未知")
    else
        IMAGE_DATE=$(date -d "$(echo $IMAGE_CREATED | cut -d'.' -f1)" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "未知")
    fi

    echo ""
    echo -e "${CYAN}现有镜像信息:${NC}"
    echo "  • 镜像 ID: ${EXISTING_IMAGE:0:12}"
    echo "  • 架构: $IMAGE_ARCH"
    echo "  • 创建时间: $IMAGE_DATE"
    echo ""

    # 检查架构是否匹配
    if [ "$IMAGE_ARCH" != "amd64" ] && [ "$ARCH" = "x86_64" ]; then
        ARCH_MISMATCH=true
        log_warn "检测到架构不匹配！"
        echo "  • 系统架构: x86_64"
        echo "  • 镜像架构: $IMAGE_ARCH"
        echo ""
    elif [ "$IMAGE_ARCH" != "arm64" ] && [ "$ARCH" = "arm64" ]; then
        ARCH_MISMATCH=true
        log_warn "检测到架构不匹配！"
        echo "  • 系统架构: arm64"
        echo "  • 镜像架构: $IMAGE_ARCH"
        echo ""
    fi
else
    log_info "未检测到已有镜像"
    echo ""
fi

# ============== 步骤 5a: 网络测速（始终执行）==============
log_info "测试镜像源网络连接速度..."
echo ""

# 定义镜像源列表（格式: 完整镜像地址|测试URL|显示名称）
REGISTRY_URLS=(
    "ghcr.io/666ghj/bettafish:latest|https://ghcr.io/v2/|官方源 (ghcr.io)"
    "ghcr.nju.edu.cn/666ghj/bettafish:latest|https://ghcr.nju.edu.cn/v2/|南京大学镜像 (ghcr.nju.edu.cn)"
    "docker.io/666ghj/bettafish:latest|https://registry-1.docker.io/v2/|Docker Hub 官方"
    "registry.cn-hangzhou.aliyuncs.com/666ghj/bettafish:latest|https://registry.cn-hangzhou.aliyuncs.com/v2/|阿里云杭州"
    "registry.cn-shanghai.aliyuncs.com/666ghj/bettafish:latest|https://registry.cn-shanghai.aliyuncs.com/v2/|阿里云上海"
)

# 测试单个镜像源的网络速度
test_registry_speed() {
    local url=$1
    local name=$2

    # 记录开始时间（纳秒级精度）
    local start_time=$(date +%s%N 2>/dev/null || date +%s)

    # 使用 curl 测试连接（下载 1MB 数据测试速度）
    if timeout 5 curl -s -r 0-1048576 "$url" > /dev/null 2>&1; then
        local end_time=$(date +%s%N 2>/dev/null || date +%s)
        # 计算耗时（毫秒）
        if [[ "$start_time" =~ [0-9]{9}$ ]]; then
            # 纳秒级支持
            local duration=$(( (end_time - start_time) / 1000000 ))
        else
            # 秒级fallback
            local duration=$(( (end_time - start_time) * 1000 ))
        fi
        echo "$duration"
    else
        # 超时或连接失败
        echo "999999"
    fi
}

# 测试所有镜像源，记录结果
BEST_REGISTRY=""
BEST_TIME=999999
BEST_NAME=""
BEST_INDEX=0
REGISTRY_INDEX=0

# 创建数组存储镜像源信息（用于后续选择，兼容 Bash 3.x）
REGISTRY_NAMES=()
REGISTRY_IMAGES=()
REGISTRY_TIMES=()

echo -e "${CYAN}${BOLD}测试结果:${NC}"
echo ""

for registry_info in "${REGISTRY_URLS[@]}"; do
    IFS='|' read -r image_url test_url name <<< "$registry_info"

    REGISTRY_INDEX=$((REGISTRY_INDEX + 1))

    echo -ne "  ${CYAN}[$REGISTRY_INDEX]${NC} ${BOLD}$name${NC} ... "

    response_time=$(test_registry_speed "$test_url" "$name")

    # 存储结果
    REGISTRY_NAMES[$REGISTRY_INDEX]=$name
    REGISTRY_IMAGES[$REGISTRY_INDEX]=$image_url
    REGISTRY_TIMES[$REGISTRY_INDEX]=$response_time

    if [ "$response_time" -eq 999999 ]; then
        echo -e "${RED}超时/失败${NC}"
    else
        echo -e "${GREEN}${response_time}ms${NC}"
    fi

    # 更新最快记录
    if [ "$response_time" -lt "$BEST_TIME" ]; then
        BEST_TIME=$response_time
        BEST_REGISTRY=$image_url
        BEST_NAME=$name
        BEST_INDEX=$REGISTRY_INDEX
    fi
done

echo ""

# 容错处理：如果所有源都失败，使用默认官方源
if [ -z "$BEST_REGISTRY" ] || [ "$BEST_TIME" -eq 999999 ]; then
    log_warn "所有镜像源测试失败，将使用默认官方源"
    BEST_REGISTRY="ghcr.io/666ghj/bettafish:latest"
    BEST_NAME="官方源 (ghcr.io)"
    BEST_TIME=999999
    BEST_INDEX=1
else
    log_success "推荐镜像源: ${BOLD}$BEST_NAME${NC} (${BEST_TIME}ms)"
fi

echo ""

# 询问用户是否使用推荐源或手动选择
echo -e "${CYAN}${BOLD}镜像源选择:${NC}"
echo ""
echo -e "  [${GREEN}0${NC}] 使用推荐的最快镜像源 (${BOLD}$BEST_NAME${NC} - ${BEST_TIME}ms)"
echo ""
for i in $(seq 1 $REGISTRY_INDEX); do
    time_display="${REGISTRY_TIMES[$i]}"
    if [ "$time_display" -eq 999999 ]; then
        time_display="${RED}失败${NC}"
    else
        time_display="${GREEN}${time_display}ms${NC}"
    fi

    if [ "$i" -eq "$BEST_INDEX" ]; then
        echo -e "  [${CYAN}$i${NC}] ${BOLD}${REGISTRY_NAMES[$i]}${NC} - $time_display ${YELLOW}← 推荐${NC}"
    else
        echo -e "  [${CYAN}$i${NC}] ${REGISTRY_NAMES[$i]} - $time_display"
    fi
done
echo ""

printf "${YELLOW}请选择镜像源 [0-$REGISTRY_INDEX] (回车默认 0): ${NC}"
read REGISTRY_CHOICE
echo ""

# 处理用户选择
if [ -z "$REGISTRY_CHOICE" ] || [ "$REGISTRY_CHOICE" = "0" ]; then
    # 使用推荐源
    SELECTED_REGISTRY=$BEST_REGISTRY
    SELECTED_NAME=$BEST_NAME
    log_info "使用推荐镜像源: ${BOLD}$SELECTED_NAME${NC}"
elif [ "$REGISTRY_CHOICE" -ge 1 ] && [ "$REGISTRY_CHOICE" -le $REGISTRY_INDEX ]; then
    # 使用用户选择的源
    SELECTED_REGISTRY=${REGISTRY_IMAGES[$REGISTRY_CHOICE]}
    SELECTED_NAME=${REGISTRY_NAMES[$REGISTRY_CHOICE]}
    SELECTED_TIME=${REGISTRY_TIMES[$REGISTRY_CHOICE]}

    if [ "$SELECTED_TIME" -eq 999999 ]; then
        log_warn "您选择的镜像源测试失败，但将尝试使用: ${BOLD}$SELECTED_NAME${NC}"
    else
        log_info "使用选择的镜像源: ${BOLD}$SELECTED_NAME${NC} (${SELECTED_TIME}ms)"
    fi
else
    # 无效选择，使用推荐源
    log_warn "无效选择，使用推荐镜像源: ${BOLD}$BEST_NAME${NC}"
    SELECTED_REGISTRY=$BEST_REGISTRY
    SELECTED_NAME=$BEST_NAME
fi

# 更新后续使用的变量
BEST_REGISTRY=$SELECTED_REGISTRY
BEST_NAME=$SELECTED_NAME

echo ""

# ============== 步骤 5b: 决定是否拉取镜像 ==============
SHOULD_PULL=false

if [ "$HAS_EXISTING_IMAGE" = false ]; then
    # 没有镜像，必须拉取
    log_info "将拉取官方预构建镜像"
    SHOULD_PULL=true
elif [ "$ARCH_MISMATCH" = true ]; then
    # 架构不匹配，必须拉取正确架构的镜像
    log_info "将自动拉取正确架构的镜像"
    SHOULD_PULL=true
else
    # 有镜像且架构匹配，提供网络状况建议
    if [ "$BEST_TIME" -lt 1000 ]; then
        # 网络很好 (< 1秒)
        echo -e "${GREEN}✓${NC} 网络状况良好 (${BEST_TIME}ms)，建议更新到最新镜像"
    elif [ "$BEST_TIME" -lt 3000 ]; then
        # 网络一般 (1-3秒)
        echo -e "${YELLOW}○${NC} 网络状况一般 (${BEST_TIME}ms)，可选择更新镜像"
    else
        # 网络较差 (> 3秒) 或超时
        echo -e "${RED}✗${NC} 网络状况较差，建议使用现有镜像"
    fi
    echo ""

    printf "${YELLOW}是否重新拉取最新镜像? [y/N] (回车默认 N): ${NC}"
    read REBUILD_CHOICE
    REBUILD_CHOICE=$(echo "$REBUILD_CHOICE" | tr '[:upper:]' '[:lower:]')
    echo ""

    if [[ "$REBUILD_CHOICE" == "y" ]]; then
        log_info "准备重新拉取镜像..."
        SHOULD_PULL=true
    else
        log_info "跳过拉取，使用现有镜像"
        SHOULD_PULL=false
    fi
fi

# ============== 步骤 5c: 配置并拉取镜像 ==============
if [ "$SHOULD_PULL" = true ]; then
    # 配置 docker-compose.yml 使用最快镜像源
    log_info "配置使用 $BEST_NAME ..."

    # 检查当前配置的镜像源
    CURRENT_IMAGE=""
    if [ -f "docker-compose.yml" ]; then
        CURRENT_IMAGE=$(grep "^\s*image:" docker-compose.yml | grep "bettafish" | grep -v "^#" | head -1 | awk '{print $2}')
    fi

    # 判断是否需要修改配置
    NEED_MODIFY=false
    if [ "$CURRENT_IMAGE" != "$BEST_REGISTRY" ]; then
        NEED_MODIFY=true
    fi

    # 只有需要修改时才备份和修改
    if [ "$NEED_MODIFY" = true ] && [ -f "docker-compose.yml" ]; then
        COMPOSE_BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        COMPOSE_BACKUP_FILE="$BACKUP_DIR/docker-compose_backup_${COMPOSE_BACKUP_TIMESTAMP}.yml"
        cp docker-compose.yml "$COMPOSE_BACKUP_FILE"
        log_info "备份配置文件到: backups/docker-compose_backup_${COMPOSE_BACKUP_TIMESTAMP}.yml"

        # 直接修改 docker-compose.yml 中的镜像地址
        # 找到 bettafish 服务的 image 行并替换
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "/bettafish:/,/image:/ s|image:.*bettafish.*|image: $BEST_REGISTRY|" docker-compose.yml
        else
            # Linux
            sed -i "/bettafish:/,/image:/ s|image:.*bettafish.*|image: $BEST_REGISTRY|" docker-compose.yml
        fi

        log_success "镜像源配置完成"
        log_info "已配置使用: $BEST_REGISTRY"
    elif [ -f "docker-compose.yml" ]; then
        log_success "镜像源已是最优配置，无需修改"
    else
        log_warn "未找到 docker-compose.yml，跳过配置"
    fi

    echo ""

    # 拉取镜像
    log_info "开始拉取官方预构建镜像..."
    log_info "镜像大小约 5GB，预计 5-15 分钟"
    echo ""

    # 记录开始时间
    PULL_START_TIME=$(date +%s)

    # 拉取镜像
    if docker-compose pull; then
        PULL_END_TIME=$(date +%s)
        PULL_DURATION=$((PULL_END_TIME - PULL_START_TIME))
        PULL_MINUTES=$((PULL_DURATION / 60))
        PULL_SECONDS=$((PULL_DURATION % 60))

        echo ""
        log_success "镜像拉取成功"
        echo ""
        echo -e "  ${CYAN}耗时:${NC} ${BOLD}${PULL_MINUTES} 分 ${PULL_SECONDS} 秒${NC}"
        echo ""

        # 验证镜像架构
        PULLED_IMAGE=$(docker images -q "$BEST_REGISTRY" 2>/dev/null)
        if [ -n "$PULLED_IMAGE" ]; then
            PULLED_ARCH=$(docker inspect --format='{{.Architecture}}' "$PULLED_IMAGE" 2>/dev/null || echo "未知")
            log_info "镜像架构: ${BOLD}$PULLED_ARCH${NC}"

            # 架构验证
            if [ "$ARCH" = "x86_64" ] && [ "$PULLED_ARCH" != "amd64" ]; then
                log_warn "警告：镜像架构 ($PULLED_ARCH) 与系统架构 (x86_64) 不匹配"
                echo "  • 这可能导致容器启动失败"
                echo "  • 请检查 docker-compose.yml 中的 platform 设置"
            elif [ "$ARCH" = "arm64" ] && [ "$PULLED_ARCH" != "arm64" ]; then
                log_warn "警告：镜像架构 ($PULLED_ARCH) 与系统架构 (arm64) 不匹配"
            else
                log_success "架构验证通过"
            fi
        fi

        # 备份保留在 backups 目录，不删除
        log_info "配置备份已保存到: $COMPOSE_BACKUP_FILE"

    else
        echo ""
        log_error "镜像拉取失败"
        echo ""
        log_info "正在恢复 docker-compose.yml ..."

        # 恢复备份
        if [ -f "$COMPOSE_BACKUP_FILE" ]; then
            cp "$COMPOSE_BACKUP_FILE" docker-compose.yml
            log_success "配置已恢复"
        fi

        echo ""
        log_info "常见问题排查:"
        echo "  1. 检查网络连接"
        echo "  2. 确认 Docker 已启动"
        echo "  3. 尝试手动拉取: docker-compose pull"
        echo ""
        exit 1
    fi
fi

progress_bar 5 7
sleep 0.5

# ================================
# 步骤 6: 启动服务
# ================================
log_step "步骤 6/7: 启动服务"

cd "$PROJECT_DIR"

# 停止并删除旧容器（如果存在）
log_info "清理旧容器..."

# 方式 1: 尝试使用 docker-compose 停止
docker-compose down 2>/dev/null || true

# 方式 2: 强制停止和删除容器（兼容 v1.x 手动启动的容器）
if docker ps -a --format '{{.Names}}' | grep -qE '^(bettafish|bettafish-db)$'; then
    log_info "检测到旧容器，强制清理..."

    # 停止容器
    docker stop bettafish bettafish-db 2>/dev/null || true

    # 删除容器
    docker rm bettafish bettafish-db 2>/dev/null || true

    log_success "旧容器已清理"
else
    log_success "无需清理容器"
fi

echo ""

# ============== 清理多余的旧镜像 ==============
log_info "检测多余镜像..."

# 定义要检查的镜像列表（可能是旧版本或本地构建的）
IMAGES_TO_CHECK=(
    "bettafish:latest"
    "ghcr.nju.edu.cn/666ghj/bettafish:latest"
    "postgres:15-alpine"
    "python:3.11-slim"
)

# 检测未使用的镜像
UNUSED_IMAGES=()
for image in "${IMAGES_TO_CHECK[@]}"; do
    if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${image}$"; then
        UNUSED_IMAGES+=("$image")
    fi
done

if [ ${#UNUSED_IMAGES[@]} -gt 0 ]; then
    log_info "检测到 ${#UNUSED_IMAGES[@]} 个可能不再需要的镜像"
    echo ""

    # 显示镜像详情
    TOTAL_SIZE=0
    for image in "${UNUSED_IMAGES[@]}"; do
        SIZE=$(docker images --format '{{.Size}}' "$image" 2>/dev/null | head -1)
        # 提取数字部分用于计算总大小（简单估算）
        SIZE_NUM=$(echo "$SIZE" | grep -oE '[0-9]+' | head -1)
        if [ -n "$SIZE_NUM" ]; then
            # 根据单位调整（MB/GB）
            if echo "$SIZE" | grep -q "GB"; then
                SIZE_NUM=$((SIZE_NUM * 1024))
            fi
            TOTAL_SIZE=$((TOTAL_SIZE + SIZE_NUM))
        fi

        if [ -n "$SIZE" ]; then
            echo -e "  ${YELLOW}•${NC} $image ${CYAN}($SIZE)${NC}"
        fi
    done

    echo ""
    if [ $TOTAL_SIZE -gt 1024 ]; then
        TOTAL_SIZE_GB=$(echo "scale=1; $TOTAL_SIZE / 1024" | bc 2>/dev/null || echo "$((TOTAL_SIZE / 1024))")
        echo -e "  ${GRAY}总大小约: ${TOTAL_SIZE_GB}GB${NC}"
    else
        echo -e "  ${GRAY}总大小约: ${TOTAL_SIZE}MB${NC}"
    fi
    echo ""

    # 增加用户确认
    log_warn "注意事项:"
    echo ""
    echo -e "  ${YELLOW}•${NC} ${BOLD}python:3.11-slim${NC} 和 ${BOLD}postgres:15-alpine${NC} 是通用镜像"
    echo "    如果您有其他项目使用这些镜像，删除后会影响那些项目"
    echo ""
    echo -e "  ${YELLOW}•${NC} ${BOLD}bettafish:latest${NC} 如果是本地构建的版本，可能包含自定义修改"
    echo "    删除后需要重新构建"
    echo ""
    echo -e "  ${YELLOW}•${NC} 删除镜像后如需使用，需要重新下载（可能需要较长时间）"
    echo ""

    printf "${YELLOW}是否删除这些镜像? [y/N] (回车默认 N): ${NC}"
    read CLEAN_IMAGES
    echo ""

    if [[ "$CLEAN_IMAGES" =~ ^[Yy]$ ]]; then
        log_info "正在清理镜像..."
        echo ""

        # 删除镜像
        CLEANED_COUNT=0
        for image in "${UNUSED_IMAGES[@]}"; do
            if docker rmi "$image" >/dev/null 2>&1; then
                CLEANED_COUNT=$((CLEANED_COUNT + 1))
                echo -e "  ${GREEN}✓${NC} 已删除: $image"
            else
                # 镜像可能被其他容器使用，跳过
                echo -e "  ${YELLOW}○${NC} 跳过: $image ${GRAY}(可能被占用)${NC}"
            fi
        done

        echo ""
        if [ $CLEANED_COUNT -gt 0 ]; then
            log_success "已清理 ${CLEANED_COUNT} 个镜像"
        else
            log_info "未清理任何镜像（镜像被占用或不存在）"
        fi
    else
        log_info "已跳过镜像清理"
        echo ""
        log_info "如果以后需要清理镜像，可以手动执行:"
        echo ""
        for image in "${UNUSED_IMAGES[@]}"; do
            echo "  ${CYAN}docker rmi $image${NC}"
        done
        echo ""
    fi
else
    log_success "未检测到可清理的镜像"
fi

echo ""

# ============== 智能端口检测与自动修复 ==============
# 检测可用端口的函数
check_port_available() {
    local port=$1
    if command_exists lsof; then
        ! lsof -i :$port >/dev/null 2>&1
    elif command_exists nc; then
        ! nc -z localhost $port 2>/dev/null
    else
        # 如果没有检测工具,假设端口可用
        return 0
    fi
}

# 查找可用端口的函数（5001-5010范围）
find_available_port() {
    for port in $(seq 5001 5010); do
        if check_port_available $port; then
            echo $port
            return 0
        fi
    done
    # 如果 5001-5010 都不可用，返回空
    echo ""
    return 1
}

# 检测端口占用情况
log_info "检测端口使用情况..."
DEFAULT_PORT=5000
FINAL_PORT=$DEFAULT_PORT
PORT_MODIFIED=false

# 检查默认端口 5000 是否可用
if ! check_port_available $DEFAULT_PORT; then
    log_warn "默认端口 ${DEFAULT_PORT} 已被占用"
    echo ""

    # 显示占用进程信息（不硬编码具体原因）
    if command_exists lsof; then
        OCCUPYING_INFO=$(lsof -i :$DEFAULT_PORT 2>/dev/null | awk 'NR==2 {print $1, $2}' | head -1)
        if [ -n "$OCCUPYING_INFO" ]; then
            echo -e "  ${CYAN}占用进程:${NC} $OCCUPYING_INFO"
        fi
    fi

    echo ""
    log_info "正在查找可用端口 (5001-5010)..."

    # 查找可用端口
    AVAILABLE_PORT=$(find_available_port)

    if [ -n "$AVAILABLE_PORT" ]; then
        FINAL_PORT=$AVAILABLE_PORT
        PORT_MODIFIED=true
        log_success "找到可用端口: ${FINAL_PORT}"
        echo ""

        # 修改 docker-compose.yml 中的端口映射
        log_info "自动修改端口配置..."

        # 备份 docker-compose.yml
        PORT_BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        PORT_BACKUP_FILE="$BACKUP_DIR/docker-compose_port_${FINAL_PORT}_${PORT_BACKUP_TIMESTAMP}.yml"
        cp docker-compose.yml "$PORT_BACKUP_FILE"

        # 修改端口映射（跨平台兼容）
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s/- \"${DEFAULT_PORT}:5000\"/- \"${FINAL_PORT}:5000\"/" docker-compose.yml
        else
            # Linux
            sed -i "s/- \"${DEFAULT_PORT}:5000\"/- \"${FINAL_PORT}:5000\"/" docker-compose.yml
        fi

        log_success "端口配置已更新: ${DEFAULT_PORT} → ${FINAL_PORT}"
        echo ""
    else
        log_error "无法找到可用端口 (5001-5010 全部被占用)"
        echo ""
        log_info "解决方案:"
        echo "  1. 关闭占用端口的程序"
        echo "  2. 手动修改 docker-compose.yml 中的端口映射"
        echo ""
        exit 1
    fi
else
    log_success "默认端口 ${DEFAULT_PORT} 可用"
    echo ""
fi

# ============== 使用 docker-compose 启动服务 ==============
if [ "$PORT_MODIFIED" = true ]; then
    log_info "使用 docker-compose 启动所有服务 (端口: ${FINAL_PORT})..."
else
    log_info "使用 docker-compose 启动所有服务..."
fi
echo ""

# 记录开始时间
START_TIME=$(date +%s)

# 启动服务（后台模式）
if docker-compose up -d; then
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    echo ""
    log_success "服务启动成功 (耗时: ${DURATION}秒)"
    echo ""

    # 端口配置备份保留在 backups 目录
    if [ "$PORT_MODIFIED" = true ]; then
        log_info "端口配置备份已保存到: backups/docker-compose_port_${FINAL_PORT}_${PORT_BACKUP_TIMESTAMP}.yml"
    fi

    # 等待服务完全启动
    log_info "等待服务完全启动..."
    sleep 5

    # 检查数据库是否就绪
    log_info "检查数据库连接..."
    DB_READY=false
    for i in {1..15}; do
        if docker-compose exec -T db pg_isready -U bettafish >/dev/null 2>&1; then
            DB_READY=true
            log_success "数据库已就绪"
            break
        fi
        sleep 1
    done

    if [ "$DB_READY" = false ]; then
        log_warn "数据库检查超时，但服务可能仍在启动中"
    fi

    # 检查应用容器日志（查找启动错误）
    echo ""
    log_info "检查应用启动状态..."
    sleep 3

    # 获取最近的日志
    APP_LOGS=$(docker-compose logs --tail=20 bettafish 2>&1)

    if echo "$APP_LOGS" | grep -qiE "error|exception|traceback|failed"; then
        log_warn "检测到应用日志中可能存在错误"
        echo ""
        echo -e "${YELLOW}最近日志（最后 10 行）:${NC}"
        echo "$APP_LOGS" | tail -10
        echo ""
        log_info "查看完整日志: ${CYAN}docker-compose logs bettafish${NC}"
    else
        log_success "应用启动正常"
    fi

    APP_PORT=$FINAL_PORT

else
    echo ""
    log_error "服务启动失败"
    echo ""

    # 恢复端口配置
    if [ "$PORT_MODIFIED" = true ] && [ -f "$PORT_BACKUP_FILE" ]; then
        log_info "正在恢复端口配置..."
        cp "$PORT_BACKUP_FILE" docker-compose.yml
        log_success "端口配置已恢复"
        echo ""
    fi

    # 显示错误日志
    log_info "查看错误日志:"
    echo ""
    docker-compose logs --tail=30

    echo ""
    log_info "常见问题排查:"
    echo "  1. 检查镜像是否成功拉取: docker images | grep bettafish"
    echo "  2. 检查架构是否匹配: docker inspect <image> --format='{{.Architecture}}'"
    echo "  3. 检查端口是否被占用: lsof -i :5000"
    echo "  4. 查看完整日志: docker-compose logs"
    echo ""
    exit 1
fi

# 如果端口被修改，保存信息供步骤 7 使用
if [ "$PORT_MODIFIED" = true ]; then
    echo "$FINAL_PORT" > /tmp/bettafish_port.txt
fi
progress_bar 6 7
sleep 0.5

# ================================
# 步骤 7: 健康检查
# ================================
log_step "步骤 7/7: 健康检查"

log_info "等待服务启动完成..."
sleep 10

# 检查容器状态
ERRORS=0

if docker ps --filter "name=bettafish" --filter "status=running" | grep -q bettafish; then
    log_success "BettaFish 容器运行正常"
else
    log_error "BettaFish 容器未运行"
    ERRORS=$((ERRORS + 1))
fi

if docker ps --filter "name=bettafish-db" --filter "status=running" | grep -q bettafish-db; then
    log_success "数据库容器运行正常"
else
    log_error "数据库容器未运行"
    ERRORS=$((ERRORS + 1))
fi

# 检查端口
log_info "检查服务端口..."
if command_exists nc; then
    if nc -z localhost $APP_PORT 2>/dev/null; then
        log_success "BettaFish 服务端口 $APP_PORT 可访问"
    else
        log_warn "端口 $APP_PORT 暂时无法访问（服务可能还在启动中）"
    fi
elif command_exists curl; then
    if curl -s http://localhost:$APP_PORT >/dev/null 2>&1; then
        log_success "BettaFish 服务端口 $APP_PORT 可访问"
    else
        log_warn "端口 $APP_PORT 暂时无法访问（服务可能还在启动中）"
    fi
fi

progress_bar 7 7
echo ""
echo ""

# ================================
# 部署完成
# ================================
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}${BOLD}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║                  🎉 部署成功！                                ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
else
    echo -e "${RED}${BOLD}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║                  ⚠️  部署完成但有警告                         ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
fi

echo -e "${CYAN}${BOLD}🌐 服务访问地址:${NC}"
echo ""
echo -e "  ${GREEN}●${NC} BettaFish 主服务:       ${BLUE}http://localhost:${APP_PORT}${NC}"
echo -e "  ${GREEN}●${NC} Insight Engine:        ${BLUE}http://localhost:8501${NC}"
echo -e "  ${GREEN}●${NC} Media Engine:          ${BLUE}http://localhost:8502${NC}"
echo -e "  ${GREEN}●${NC} Query Engine:          ${BLUE}http://localhost:8503${NC}"
echo -e "  ${GREEN}●${NC} 数据库服务:            ${BLUE}localhost:5432${NC}"
echo ""

# 如果使用的不是默认端口,提示用户
if [ "$APP_PORT" != "5000" ]; then
    echo -e "  ${YELLOW}💡 提示:${NC} 由于端口 5000 被占用,已自动使用端口 ${APP_PORT}"
    echo ""
fi

echo -e "${CYAN}${BOLD}📦 容器管理命令:${NC}"
echo ""
echo -e "  ${YELLOW}查看应用日志:${NC}  docker logs -f bettafish"
echo -e "  ${YELLOW}查看数据库日志:${NC}docker logs -f bettafish-db"
echo -e "  ${YELLOW}停止服务:${NC}      docker stop bettafish bettafish-db"
echo -e "  ${YELLOW}启动服务:${NC}      docker start bettafish bettafish-db"
echo -e "  ${YELLOW}重启服务:${NC}      docker restart bettafish"
echo -e "  ${YELLOW}查看状态:${NC}      docker ps"
echo ""

echo -e "${CYAN}${BOLD}🔧 快速访问:${NC}"
echo ""
echo -e "  ${BLUE}浏览器打开:${NC} http://localhost:${APP_PORT}"
echo -e "  ${BLUE}命令行测试:${NC} curl http://localhost:${APP_PORT}"
echo ""

echo -e "${CYAN}${BOLD}📁 项目位置:${NC}"
echo ""
echo -e "  ${BLUE}${PROJECT_DIR}${NC}"
echo ""

if [ $ERRORS -gt 0 ]; then
    echo -e "${YELLOW}${BOLD}⚠️  故障排查:${NC}"
    echo ""
    echo -e "  1. 查看容器日志: docker logs bettafish"
    echo -e "  2. 检查容器状态: docker ps -a"
    echo -e "  3. 重新启动服务: docker restart bettafish"
    echo ""
fi

log_success "部署流程完成！"

# 显示下一步建议
echo -e "${CYAN}${BOLD}💡 下一步:${NC}"
echo ""
echo -e "  1. 等待 1-2 分钟让服务完全启动"
echo -e "  2. 访问 ${BLUE}http://localhost:${APP_PORT}${NC} 测试服务"
echo -e "  3. 查看日志确认服务运行正常: ${YELLOW}docker logs -f bettafish${NC}"
echo ""

# 询问是否打开浏览器
echo -e "${CYAN}${BOLD}🌐 是否使用默认浏览器打开服务页面？${NC}"
echo ""
echo -e "  ${GREEN}[Y]${NC} 是 (默认)"
echo -e "  ${RED}[N]${NC} 否"
echo ""
read -p "请选择 [Y/n]: " -n 1 -r OPEN_BROWSER
echo ""

# 默认为 Y
if [[ -z "$OPEN_BROWSER" ]]; then
    OPEN_BROWSER="Y"
fi

if [[ $OPEN_BROWSER =~ ^[Yy]$ ]]; then
    echo ""
    log_info "正在打开浏览器..."

    # 检测操作系统并使用相应的命令打开浏览器
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        open "http://localhost:${APP_PORT}"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v xdg-open > /dev/null; then
            xdg-open "http://localhost:${APP_PORT}" >/dev/null 2>&1
        elif command -v gnome-open > /dev/null; then
            gnome-open "http://localhost:${APP_PORT}" >/dev/null 2>&1
        else
            log_warn "未检测到浏览器命令，请手动访问: http://localhost:${APP_PORT}"
        fi
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        # Windows (Git Bash / Cygwin)
        start "http://localhost:${APP_PORT}"
    else
        log_warn "未识别的操作系统，请手动访问: http://localhost:${APP_PORT}"
    fi

    sleep 1
    log_success "浏览器已打开"
    echo ""
else
    echo ""
    log_info "已跳过浏览器打开，请手动访问: ${BLUE}http://localhost:${APP_PORT}${NC}"
    echo ""
fi
