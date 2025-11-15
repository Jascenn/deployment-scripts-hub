#!/bin/bash

# BettaFish 端口访问诊断脚本

echo "=========================================="
echo "BettaFish 端口访问诊断"
echo "=========================================="
echo ""

# 1. 检查容器状态
echo "1. 检查容器运行状态："
docker ps -a | grep bettafish
echo ""

# 2. 检查端口监听
echo "2. 检查端口监听状态："
echo "本地端口监听："
netstat -tlnp 2>/dev/null | grep -E ':(5000|8501|8502|8503)' || ss -tlnp 2>/dev/null | grep -E ':(5000|8501|8502|8503)'
echo ""

# 3. 检查 Docker 端口映射
echo "3. 检查 Docker 端口映射："
docker port bettafish 2>/dev/null
echo ""

# 4. 检查防火墙状态
echo "4. 检查防火墙状态："
if command -v firewall-cmd >/dev/null 2>&1; then
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
    echo "未检测到 firewalld 或 ufw"
fi
echo ""

# 5. 测试本地访问
echo "5. 测试本地访问："
curl -s -o /dev/null -w "localhost:5000 - HTTP状态码: %{http_code}\n" http://localhost:5000 --connect-timeout 3 || echo "localhost:5000 - 连接失败"
echo ""

# 6. 检查容器日志（最后20行）
echo "6. 容器日志（最后20行）："
docker logs --tail 20 bettafish 2>&1 | head -20
echo ""

# 7. 检查网络接口
echo "7. 网络接口和监听地址："
docker inspect bettafish 2>/dev/null | grep -A 10 "NetworkSettings" | grep -E "(IPAddress|Ports)"
echo ""

echo "=========================================="
echo "诊断完成"
echo "=========================================="
