#!/bin/bash

# BettaFish 端口访问诊断脚本 - 兼容 Linux 和 macOS

# 检测操作系统
OS_TYPE=$(uname -s)

echo "=========================================="
echo "BettaFish 端口访问诊断"
echo "=========================================="
echo "操作系统: $OS_TYPE"
echo ""

# 1. 检查 Docker 是否运行
echo "1. 检查 Docker 状态："
if docker info >/dev/null 2>&1; then
    echo "✅ Docker 正在运行"
    docker --version
else
    echo "❌ Docker 未运行或未安装"
    exit 1
fi
echo ""

# 2. 检查容器状态
echo "2. 检查容器运行状态："
CONTAINERS=$(docker ps -a --filter "name=bettafish" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}")
if [ -z "$CONTAINERS" ] || [ "$CONTAINERS" = "NAMES	STATUS	PORTS" ]; then
    echo "❌ 未找到 bettafish 相关容器"
else
    echo "$CONTAINERS"
fi
echo ""

# 3. 检查端口监听
echo "3. 检查端口监听状态："
echo "本地端口监听："
if [ "$OS_TYPE" = "Darwin" ]; then
    # macOS 使用 lsof
    if command -v lsof >/dev/null 2>&1; then
        echo ""
        echo "端口 5000:"
        lsof -nP -iTCP:5000 -sTCP:LISTEN 2>/dev/null || echo "  未监听"
        echo ""
        echo "端口 8501:"
        lsof -nP -iTCP:8501 -sTCP:LISTEN 2>/dev/null || echo "  未监听"
        echo ""
        echo "端口 8502:"
        lsof -nP -iTCP:8502 -sTCP:LISTEN 2>/dev/null || echo "  未监听"
        echo ""
        echo "端口 8503:"
        lsof -nP -iTCP:8503 -sTCP:LISTEN 2>/dev/null || echo "  未监听"
    else
        netstat -an | grep -E 'LISTEN.*(5000|8501|8502|8503)' || echo "  未找到相关端口监听"
    fi
else
    # Linux 使用 netstat 或 ss
    netstat -tlnp 2>/dev/null | grep -E ':(5000|8501|8502|8503)' || ss -tlnp 2>/dev/null | grep -E ':(5000|8501|8502|8503)' || echo "  未找到相关端口监听"
fi
echo ""

# 4. 检查 Docker 端口映射
echo "4. 检查 Docker 端口映射："
MAIN_CONTAINER=$(docker ps --filter "name=bettafish" --filter "status=running" --format "{{.Names}}" | grep -v "db" | head -1)
if [ -n "$MAIN_CONTAINER" ]; then
    echo "容器名称: $MAIN_CONTAINER"
    docker port "$MAIN_CONTAINER" 2>/dev/null || echo "  无端口映射信息"
else
    echo "❌ 未找到运行中的 bettafish 主容器"
fi
echo ""

# 5. 检查防火墙状态
echo "5. 检查防火墙状态："
if [ "$OS_TYPE" = "Darwin" ]; then
    # macOS 防火墙
    FW_STATUS=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "$FW_STATUS"
    else
        echo "无法获取防火墙状态（可能需要管理员权限）"
    fi
elif command -v firewall-cmd >/dev/null 2>&1; then
    echo "防火墙类型: firewalld"
    echo "防火墙状态："
    firewall-cmd --state 2>/dev/null || echo "无法获取状态"
    echo "开放的端口："
    firewall-cmd --list-ports 2>/dev/null || echo "无法获取端口列表"
elif command -v ufw >/dev/null 2>&1; then
    echo "防火墙类型: ufw"
    echo "防火墙状态："
    ufw status 2>/dev/null || echo "无法获取状态"
else
    echo "未检测到防火墙管理工具"
fi
echo ""

# 6. 测试本地访问
echo "6. 测试本地访问："
echo "测试主应用端口..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000 --connect-timeout 3 2>/dev/null)
if [ $? -eq 0 ]; then
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ localhost:5000 - HTTP状态码: $HTTP_CODE (正常)"
    elif [ "$HTTP_CODE" = "403" ]; then
        echo "⚠️  localhost:5000 - HTTP状态码: $HTTP_CODE (服务运行但拒绝访问)"
    else
        echo "⚠️  localhost:5000 - HTTP状态码: $HTTP_CODE"
    fi
else
    echo "❌ localhost:5000 - 连接失败"
fi

echo ""
echo "测试 Streamlit 端口..."
for port in 8501 8502 8503; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$port --connect-timeout 3 2>/dev/null)
    if [ $? -eq 0 ]; then
        if [ "$HTTP_CODE" = "200" ]; then
            echo "✅ localhost:$port - HTTP状态码: $HTTP_CODE (正常)"
        else
            echo "⚠️  localhost:$port - HTTP状态码: $HTTP_CODE"
        fi
    else
        echo "❌ localhost:$port - 连接失败"
    fi
done
echo ""

# 7. 检查容器日志（最后20行）
echo "7. 容器日志（最后20行）："
if [ -n "$MAIN_CONTAINER" ]; then
    echo "--- $MAIN_CONTAINER 日志 ---"
    docker logs --tail 20 "$MAIN_CONTAINER" 2>&1 | tail -20
else
    ALL_BETTAFISH=$(docker ps -a --filter "name=bettafish" --format "{{.Names}}" | head -1)
    if [ -n "$ALL_BETTAFISH" ]; then
        echo "--- $ALL_BETTAFISH 日志 (容器已停止) ---"
        docker logs --tail 20 "$ALL_BETTAFISH" 2>&1 | tail -20
    else
        echo "❌ 未找到容器，无法获取日志"
    fi
fi
echo ""

# 8. 检查网络接口
echo "8. Docker 网络配置："
if [ -n "$MAIN_CONTAINER" ]; then
    echo "容器 IP 地址:"
    docker inspect "$MAIN_CONTAINER" 2>/dev/null | grep -A 5 '"IPAddress"' | grep -E 'IPAddress.*[0-9]' || echo "  无法获取 IP 地址"
    echo ""
    echo "端口映射详情:"
    docker inspect "$MAIN_CONTAINER" 2>/dev/null | grep -A 30 '"Ports"' | head -35 || echo "  无法获取端口映射"
else
    echo "❌ 容器未运行，无法检查网络配置"
fi
echo ""

echo "=========================================="
echo "诊断完成"
echo "=========================================="
echo ""
echo "💡 常见问题排查:"
echo "  1. 如果容器未运行 → 检查是否执行了部署脚本"
echo "  2. 如果端口未监听 → 检查容器是否正常启动，查看容器日志"
echo "  3. 如果 HTTP 403 → 可能需要配置 .env 文件"
echo "  4. 如果连接失败 → 检查 Docker 是否运行，端口是否被占用"
echo ""
