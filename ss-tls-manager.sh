#!/bin/bash

# Shadowsocks 2022 + Shadow TLS V3 一键部署/卸载脚本
# 支持 Ubuntu/Debian/CentOS

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 检查安装状态
check_installation_status() {
    SS_INSTALLED=false
    STLS_INSTALLED=false
    SS_RUNNING=false
    STLS_RUNNING=false
    
    # 检查 Shadowsocks 安装状态
    if [[ -f /usr/local/bin/ssserver ]] && [[ -f /etc/systemd/system/shadowsocks.service ]]; then
        SS_INSTALLED=true
        if systemctl is-active --quiet shadowsocks 2>/dev/null; then
            SS_RUNNING=true
        fi
    fi
    
    # 检查 Shadow TLS 安装状态
    if [[ -f /usr/local/bin/shadow-tls ]] && [[ -f /etc/systemd/system/shadow-tls.service ]]; then
        STLS_INSTALLED=true
        if systemctl is-active --quiet shadow-tls 2>/dev/null; then
            STLS_RUNNING=true
        fi
    fi
}

# 获取端口信息
get_port_info() {
    SS_PORT=""
    TLS_PORT=""
    
    if [[ -f /etc/shadowsocks/config.json ]]; then
        SS_PORT=$(grep -o '"server_port":[[:space:]]*[0-9]*' /etc/shadowsocks/config.json | grep -o '[0-9]*')
    fi
    
    if [[ -f /etc/systemd/system/shadow-tls.service ]]; then
        TLS_PORT=$(grep -o '\[::\]:[0-9]*' /etc/systemd/system/shadow-tls.service | grep -o '[0-9]*')
    fi
}

# 显示系统状态
show_system_status() {
    check_installation_status
    get_port_info
    
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}           系统状态检查${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    # Shadowsocks 状态
    echo -e "\n${YELLOW}📦 Shadowsocks 状态:${NC}"
    if $SS_INSTALLED; then
        echo -e "   安装状态: ${GREEN}✅ 已安装${NC}"
        if $SS_RUNNING; then
            echo -e "   运行状态: ${GREEN}✅ 正在运行${NC}"
            [[ -n "$SS_PORT" ]] && echo -e "   监听端口: ${BLUE}$SS_PORT${NC}"
        else
            echo -e "   运行状态: ${RED}❌ 未运行${NC}"
        fi
    else
        echo -e "   安装状态: ${RED}❌ 未安装${NC}"
        echo -e "   运行状态: ${RED}❌ 未运行${NC}"
    fi
    
    # Shadow TLS 状态
    echo -e "\n${YELLOW}🔒 Shadow TLS 状态:${NC}"
    if $STLS_INSTALLED; then
        echo -e "   安装状态: ${GREEN}✅ 已安装${NC}"
        if $STLS_RUNNING; then
            echo -e "   运行状态: ${GREEN}✅ 正在运行${NC}"
            [[ -n "$TLS_PORT" ]] && echo -e "   监听端口: ${BLUE}$TLS_PORT${NC}"
        else
            echo -e "   运行状态: ${RED}❌ 未运行${NC}"
        fi
    else
        echo -e "   安装状态: ${RED}❌ 未安装${NC}"
        echo -e "   运行状态: ${RED}❌ 未运行${NC}"
    fi
    
    # 配置文件状态
    echo -e "\n${YELLOW}📄 配置文件状态:${NC}"
    if [[ -f /root/ss-tls-config.txt ]]; then
        echo -e "   配置文件: ${GREEN}✅ 存在${NC} (/root/ss-tls-config.txt)"
    else
        echo -e "   配置文件: ${RED}❌ 不存在${NC}"
    fi
    
    # 端口监听状态
    echo -e "\n${YELLOW}🌐 端口监听状态:${NC}"
    local listening_ports=$(ss -tulpn 2>/dev/null | grep -E "(ssserver|shadow-tls)" | wc -l)
    if [[ $listening_ports -gt 0 ]]; then
        echo -e "   监听状态: ${GREEN}✅ 正常${NC}"
        ss -tulpn 2>/dev/null | grep -E "(ssserver|shadow-tls)" | while read line; do
            echo -e "   ${BLUE}$line${NC}"
        done
    else
        echo -e "   监听状态: ${RED}❌ 无相关端口监听${NC}"
    fi
    
    # 整体状态总结
    echo -e "\n${YELLOW}📊 整体状态:${NC}"
    if $SS_INSTALLED && $STLS_INSTALLED && $SS_RUNNING && $STLS_RUNNING; then
        echo -e "   ${GREEN}✅ 服务完全正常，可以使用${NC}"
    elif $SS_INSTALLED && $STLS_INSTALLED; then
        echo -e "   ${YELLOW}⚠️  服务已安装但未完全运行${NC}"
    elif $SS_INSTALLED || $STLS_INSTALLED; then
        echo -e "   ${YELLOW}⚠️  部分服务已安装${NC}"
    else
        echo -e "   ${RED}❌ 服务未安装${NC}"
    fi
    
    echo -e "${CYAN}========================================${NC}"
}

# 显示菜单
show_menu() {
    clear
    
    # 显示系统状态
    show_system_status
    
    echo
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Shadowsocks 2022 + Shadow TLS V3${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    echo -e "${YELLOW}请选择操作：${NC}"
    
    # 根据安装状态调整菜单显示
    check_installation_status
    
    if ! $SS_INSTALLED && ! $STLS_INSTALLED; then
        echo -e "${GREEN}1) 🚀 安装 Shadowsocks + Shadow TLS${NC}"
    elif $SS_INSTALLED && $STLS_INSTALLED; then
        if $SS_RUNNING && $STLS_RUNNING; then
            echo -e "1) ✅ 重新安装 Shadowsocks + Shadow TLS"
        else
            echo -e "${YELLOW}1) 🔧 重新安装 Shadowsocks + Shadow TLS${NC}"
        fi
        echo -e "${RED}2) 🗑️  卸载 Shadowsocks + Shadow TLS${NC}"
        echo -e "3) 📋 查看配置信息"
        echo -e "4) 🔄 重启服务"
        echo -e "6) 📝 查看日志"
    else
        echo -e "${YELLOW}1) 🔧 完成安装 Shadowsocks + Shadow TLS${NC}"
        echo -e "${RED}2) 🗑️  卸载已安装组件${NC}"
    fi
    
    echo -e "5) 📊 查看详细状态"
    echo -e "7) 🔧 故障排除"
    echo -e "0) 🚪 退出"
    echo
    read -p "请输入选项 [0-7]: " choice
}

# 故障排除功能
troubleshoot() {
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}           故障排除${NC}"
    echo -e "${YELLOW}========================================${NC}"
    
    check_installation_status
    
    echo -e "\n${BLUE}🔍 正在检查常见问题...${NC}\n"
    
    # 检查服务状态
    if $SS_INSTALLED && ! $SS_RUNNING; then
        echo -e "${RED}❌ Shadowsocks 服务未运行${NC}"
        echo -e "   尝试启动: ${CYAN}systemctl start shadowsocks${NC}"
        echo -e "   查看日志: ${CYAN}journalctl -u shadowsocks${NC}"
        echo
    fi
    
    if $STLS_INSTALLED && ! $STLS_RUNNING; then
        echo -e "${RED}❌ Shadow TLS 服务未运行${NC}"
        echo -e "   尝试启动: ${CYAN}systemctl start shadow-tls${NC}"
        echo -e "   查看日志: ${CYAN}journalctl -u shadow-tls${NC}"
        echo
    fi
    
    # 检查端口占用
    if [[ -n "$TLS_PORT" ]]; then
        local port_check=$(ss -tulpn | grep ":$TLS_PORT " | wc -l)
        if [[ $port_check -eq 0 ]] && $STLS_INSTALLED; then
            echo -e "${RED}❌ Shadow TLS 端口 $TLS_PORT 未监听${NC}"
        fi
    fi
    
    if [[ -n "$SS_PORT" ]]; then
        local port_check=$(ss -tulpn | grep ":$SS_PORT " | wc -l)
        if [[ $port_check -eq 0 ]] && $SS_INSTALLED; then
            echo -e "${RED}❌ Shadowsocks 端口 $SS_PORT 未监听${NC}"
        fi
    fi
    
    # 检查防火墙
    echo -e "${BLUE}🔥 防火墙检查:${NC}"
    if command -v ufw >/dev/null 2>&1; then
        echo -e "   UFW 状态: $(ufw status | head -1)"
    elif command -v firewall-cmd >/dev/null 2>&1; then
        echo -e "   Firewalld 状态: $(systemctl is-active firewalld)"
    else
        echo -e "   使用 iptables"
    fi
    
    # 提供修复选项
    echo -e "\n${YELLOW}🛠️  快速修复选项:${NC}"
    echo "1) 重启所有服务"
    echo "2) 重新加载配置"
    echo "3) 检查并修复防火墙"
    echo "4) 查看详细错误日志"
    echo "0) 返回主菜单"
    
    read -p "选择修复选项 [0-4]: " fix_choice
    
    case $fix_choice in
        1)
            log_info "重启服务..."
            systemctl restart shadowsocks shadow-tls 2>/dev/null || true
            sleep 2
            show_system_status
            ;;
        2)
            log_info "重新加载配置..."
            systemctl daemon-reload
            systemctl restart shadowsocks shadow-tls 2>/dev/null || true
            ;;
        3)
            log_info "检查防火墙..."
            get_port_info
            if [[ -n "$TLS_PORT" ]] && [[ -n "$SS_PORT" ]]; then
                configure_firewall_fix
            else
                log_error "无法获取端口信息"
            fi
            ;;
        4)
            echo -e "\n${YELLOW}Shadowsocks 错误日志:${NC}"
            journalctl -u shadowsocks --no-pager -l | tail -10
            echo -e "\n${YELLOW}Shadow TLS 错误日志:${NC}"
            journalctl -u shadow-tls --no-pager -l | tail -10
            ;;
        0)
            return
            ;;
    esac
}

# 修复防火墙配置
configure_firewall_fix() {
    log_info "修复防火墙配置..."
    
    if command -v ufw >/dev/null 2>&1; then
        ufw allow $TLS_PORT/tcp 2>/dev/null || true
        ufw allow $SS_PORT/udp 2>/dev/null || true
        log_success "UFW 规则已更新"
    elif command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --permanent --add-port=$TLS_PORT/tcp 2>/dev/null || true
        firewall-cmd --permanent --add-port=$SS_PORT/udp 2>/dev/null || true
        firewall-cmd --reload 2>/dev/null || true
        log_success "Firewalld 规则已更新"
    else
        iptables -I INPUT -p tcp --dport $TLS_PORT -j ACCEPT 2>/dev/null || true
        iptables -I INPUT -p udp --dport $SS_PORT -j ACCEPT 2>/dev/null || true
        log_success "iptables 规则已更新"
    fi
}

# 检查系统
check_system() {
    if [[ -f /etc/redhat-release ]]; then
        OS="centos"
    elif cat /etc/issue | grep -Eqi "debian"; then
        OS="debian"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        OS="ubuntu"
    else
        log_error "不支持的操作系统"
        exit 1
    fi
    
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            ARCH="x86_64"
            ;;
        aarch64|arm64)
            ARCH="arm"
            ;;
        *)
            log_error "不支持的架构: $ARCH"
            exit 1
            ;;
    esac
    
    log_info "检测到系统: $OS, 架构: $ARCH"
}

# 安装依赖
install_dependencies() {
    log_info "安装依赖包..."
    
    case $OS in
        centos)
            yum update -y
            yum install -y curl wget unzip systemd
            ;;
        ubuntu|debian)
            apt update -y
            apt install -y curl wget unzip systemd
            ;;
    esac
}

# 生成随机密码
generate_password() {
    local length=$1
    if command -v openssl >/dev/null 2>&1; then
        openssl rand -base64 $length | tr -d "=+/" | cut -c1-$length
    else
        cat /dev/urandom | tr -dc 'A-Za-z0-9' | head -c $length
    fi
}

# 生成 SS2022 密码
generate_ss_password() {
    if command -v openssl >/dev/null 2>&1; then
        openssl rand -base64 32
    else
        generate_password 44
    fi
}

# 获取用户输入
get_user_input() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Shadowsocks 2022 + Shadow TLS V3${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    
    # SS 端口
    read -p "请输入 Shadowsocks 端口 (默认: 随机生成): " SS_PORT
    if [[ -z "$SS_PORT" ]]; then
        SS_PORT=$((RANDOM % 55535 + 10000))
    fi
    
    # Shadow TLS 端口
    read -p "请输入 Shadow TLS 端口 (默认: 443): " TLS_PORT
    if [[ -z "$TLS_PORT" ]]; then
        TLS_PORT=443
    fi
    
    # SS 密码
    read -p "请输入 Shadowsocks 密码 (默认: 随机生成): " SS_PASSWORD
    if [[ -z "$SS_PASSWORD" ]]; then
        SS_PASSWORD=$(generate_ss_password)
    fi
    
    # Shadow TLS 密码
    read -p "请输入 Shadow TLS 密码 (默认: 随机生成): " TLS_PASSWORD
    if [[ -z "$TLS_PASSWORD" ]]; then
        TLS_PASSWORD=$(generate_password 16)
    fi
    
    # 伪装域名
    read -p "请输入伪装域名 (默认: p11.douyinpic.com): " FAKE_DOMAIN
    if [[ -z "$FAKE_DOMAIN" ]]; then
        FAKE_DOMAIN="p11.douyinpic.com"
    fi
    
    # 加密方式
    echo "请选择加密方式:"
    echo "1) 2022-blake3-aes-256-gcm (推荐)"
    echo "2) 2022-blake3-aes-128-gcm"
    echo "3) 2022-blake3-chacha20-poly1305"
    read -p "请选择 (默认: 1): " ENCRYPT_CHOICE
    
    case $ENCRYPT_CHOICE in
        2)
            ENCRYPT_METHOD="2022-blake3-aes-128-gcm"
            ;;
        3)
            ENCRYPT_METHOD="2022-blake3-chacha20-poly1305"
            ;;
        *)
            ENCRYPT_METHOD="2022-blake3-aes-256-gcm"
            ;;
    esac
    
    # 是否启用 wildcard SNI
    read -p "是否启用 wildcard SNI (降低安全性但提高灵活性) [y/N]: " WILDCARD_SNI
    if [[ "$WILDCARD_SNI" =~ ^[Yy]$ ]]; then
        WILDCARD_SNI_FLAG="--wildcard-sni=authed"
    else
        WILDCARD_SNI_FLAG=""
    fi
    
    # 获取服务器 IP
    SERVER_IP=$(curl -s ipv4.icanhazip.com || curl -s ifconfig.me || curl -s ipinfo.io/ip)
    if [[ -z "$SERVER_IP" ]]; then
        read -p "无法自动获取服务器 IP，请手动输入: " SERVER_IP
    fi
    
    echo
    log_info "配置信息确认:"
    echo "服务器 IP: $SERVER_IP"
    echo "Shadowsocks 端口: $SS_PORT"
    echo "Shadow TLS 端口: $TLS_PORT"
    echo "加密方式: $ENCRYPT_METHOD"
    echo "伪装域名: $FAKE_DOMAIN"
    echo "Wildcard SNI: $([ -n "$WILDCARD_SNI_FLAG" ] && echo "启用" || echo "禁用")"
    echo
    read -p "确认部署? [Y/n]: " CONFIRM
    if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
        log_error "部署已取消"
        exit 1
    fi
}

# 安装 Shadowsocks
install_shadowsocks() {
    log_info "安装 Shadowsocks..."
    
    # 下载 shadowsocks-rust
    SS_VERSION="v1.17.1"
    if [[ "$ARCH" == "x86_64" ]]; then
        SS_URL="https://github.com/shadowsocks/shadowsocks-rust/releases/download/${SS_VERSION}/shadowsocks-${SS_VERSION}.x86_64-unknown-linux-gnu.tar.xz"
    else
        SS_URL="https://github.com/shadowsocks/shadowsocks-rust/releases/download/${SS_VERSION}/shadowsocks-${SS_VERSION}.aarch64-unknown-linux-gnu.tar.xz"
    fi
    
    cd /tmp
    wget -O shadowsocks.tar.xz "$SS_URL"
    tar -xf shadowsocks.tar.xz
    mv ssserver /usr/local/bin/
    chmod +x /usr/local/bin/ssserver
    
    # 创建配置文件
    mkdir -p /etc/shadowsocks
    cat > /etc/shadowsocks/config.json << EOF
{
    "server": "0.0.0.0",
    "server_port": $SS_PORT,
    "password": "$SS_PASSWORD",
    "method": "$ENCRYPT_METHOD",
    "mode": "tcp_and_udp",
    "fast_open": true,
    "no_delay": true
}
EOF

    # 创建 systemd 服务
    cat > /etc/systemd/system/shadowsocks.service << EOF
[Unit]
Description=Shadowsocks Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
LimitNOFILE=32768
ExecStart=/usr/local/bin/ssserver -c /etc/shadowsocks/config.json
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
}

# 安装 Shadow TLS
install_shadow_tls() {
    log_info "安装 Shadow TLS..."
    
    # 下载 Shadow TLS
    if [[ "$ARCH" == "x86_64" ]]; then
        STLS_URL="https://github.com/ihciah/shadow-tls/releases/download/v0.2.25/shadow-tls-x86_64-unknown-linux-musl"
    else
        STLS_URL="https://github.com/ihciah/shadow-tls/releases/download/v0.2.25/shadow-tls-arm-unknown-linux-musleabi"
    fi
    
    curl -L "$STLS_URL" -o /usr/local/bin/shadow-tls
    chmod +x /usr/local/bin/shadow-tls
    
    # 创建 systemd 服务
    cat > /etc/systemd/system/shadow-tls.service << EOF
[Unit]
Description=Shadow-TLS Server Service
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
LimitNOFILE=32767
Type=simple
User=root
Restart=on-failure
RestartSec=5s
ExecStartPre=/bin/sh -c 'ulimit -n 51200'
ExecStart=/usr/local/bin/shadow-tls --fastopen --v3 --strict server $WILDCARD_SNI_FLAG --listen [::]:$TLS_PORT --server 127.0.0.1:$SS_PORT --tls $FAKE_DOMAIN:443 --password $TLS_PASSWORD

[Install]
WantedBy=multi-user.target
EOF
}

# 配置防火墙
configure_firewall() {
    log_info "配置防火墙..."
    
    # 检查并配置 iptables/ufw
    if command -v ufw >/dev/null 2>&1; then
        ufw allow $TLS_PORT/tcp
        ufw allow $SS_PORT/udp
        echo "y" | ufw enable 2>/dev/null || true
    elif command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --permanent --add-port=$TLS_PORT/tcp
        firewall-cmd --permanent --add-port=$SS_PORT/udp
        firewall-cmd --reload
    else
        # 使用 iptables
        iptables -I INPUT -p tcp --dport $TLS_PORT -j ACCEPT
        iptables -I INPUT -p udp --dport $SS_PORT -j ACCEPT
        # 尝试保存规则
        if command -v iptables-save >/dev/null 2>&1; then
            iptables-save > /etc/iptables.rules 2>/dev/null || true
        fi
        log_warn "请确保防火墙已开放端口 $TLS_PORT/tcp 和 $SS_PORT/udp"
    fi
}

# 启动服务
start_services() {
    log_info "启动服务..."
    
    systemctl daemon-reload
    systemctl enable shadowsocks shadow-tls
    systemctl start shadowsocks shadow-tls
    
    sleep 3
    
    # 检查服务状态
    if systemctl is-active --quiet shadowsocks; then
        log_success "Shadowsocks 服务启动成功"
    else
        log_error "Shadowsocks 服务启动失败"
        systemctl status shadowsocks
        exit 1
    fi
    
    if systemctl is-active --quiet shadow-tls; then
        log_success "Shadow TLS 服务启动成功"
    else
        log_error "Shadow TLS 服务启动失败"
        systemctl status shadow-tls
        exit 1
    fi
}

# 生成客户端配置
generate_config() {
    log_info "生成客户端配置..."
    
    echo
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}         部署完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo
    echo -e "${YELLOW}服务器信息:${NC}"
    echo "服务器 IP: $SERVER_IP"
    echo "Shadow TLS 端口: $TLS_PORT"
    echo "Shadowsocks 端口: $SS_PORT"
    echo "加密方式: $ENCRYPT_METHOD"
    echo "SS 密码: $SS_PASSWORD"
    echo "TLS 密码: $TLS_PASSWORD"
    echo "伪装域名: $FAKE_DOMAIN"
    echo
    echo -e "${YELLOW}Surge 配置:${NC}"
    echo "----------------------------------------"
    echo "ss-tls = ss, $SERVER_IP, $TLS_PORT, encrypt-method=$ENCRYPT_METHOD, password=$SS_PASSWORD, shadow-tls-password=$TLS_PASSWORD, shadow-tls-sni=$FAKE_DOMAIN, shadow-tls-version=3, udp-relay=true, udp-port=$SS_PORT"
    echo "----------------------------------------"
    echo
    echo -e "${YELLOW}Clash Meta 配置:${NC}"
    echo "----------------------------------------"
    cat << EOF
proxies:
  - name: "ss-tls"
    type: ss
    server: $SERVER_IP
    port: $TLS_PORT
    cipher: $ENCRYPT_METHOD
    password: "$SS_PASSWORD"
    plugin: shadow-tls
    plugin-opts:
      host: "$FAKE_DOMAIN"
      password: "$TLS_PASSWORD"
      version: 3
    udp: true
EOF
    echo "----------------------------------------"
    echo
    echo -e "${YELLOW}管理命令:${NC}"
    echo "查看 SS 状态: systemctl status shadowsocks"
    echo "查看 TLS 状态: systemctl status shadow-tls"
    echo "查看 SS 日志: journalctl -f -u shadowsocks"
    echo "查看 TLS 日志: journalctl -f -u shadow-tls"
    echo "重启 SS: systemctl restart shadowsocks"
    echo "重启 TLS: systemctl restart shadow-tls"
    echo
    
    # 保存配置到文件
    cat > /root/ss-tls-config.txt << EOF
========================================
Shadowsocks 2022 + Shadow TLS V3 配置
========================================

服务器信息:
服务器 IP: $SERVER_IP
Shadow TLS 端口: $TLS_PORT
Shadowsocks 端口: $SS_PORT
加密方式: $ENCRYPT_METHOD
SS 密码: $SS_PASSWORD
TLS 密码: $TLS_PASSWORD
伪装域名: $FAKE_DOMAIN

Surge 配置:
ss-tls = ss, $SERVER_IP, $TLS_PORT, encrypt-method=$ENCRYPT_METHOD, password=$SS_PASSWORD, shadow-tls-password=$TLS_PASSWORD, shadow-tls-sni=$FAKE_DOMAIN, shadow-tls-version=3, udp-relay=true, udp-port=$SS_PORT

Clash Meta 配置:
proxies:
  - name: "ss-tls"
    type: ss
    server: $SERVER_IP
    port: $TLS_PORT
    cipher: $ENCRYPT_METHOD
    password: "$SS_PASSWORD"
    plugin: shadow-tls
    plugin-opts:
      host: "$FAKE_DOMAIN"
      password: "$TLS_PASSWORD"
      version: 3
    udp: true

管理命令:
systemctl status shadowsocks
systemctl status shadow-tls
journalctl -f -u shadowsocks
journalctl -f -u shadow-tls
EOF
    
    log_success "配置已保存到 /root/ss-tls-config.txt"
}

# 卸载功能
uninstall_ss_tls() {
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}         卸载确认${NC}"
    echo -e "${RED}========================================${NC}"
    echo
    log_warn "此操作将完全删除 Shadowsocks 和 Shadow TLS"
    log_warn "包括所有配置文件、服务和二进制文件"
    echo
    read -p "确认卸载? 输入 'YES' 继续: " UNINSTALL_CONFIRM
    
    if [[ "$UNINSTALL_CONFIRM" != "YES" ]]; then
        log_info "卸载已取消"
        return
    fi
    
    log_info "开始卸载..."
    
    # 停止并禁用服务
    log_info "停止服务..."
    systemctl stop shadowsocks shadow-tls 2>/dev/null || true
    systemctl disable shadowsocks shadow-tls 2>/dev/null || true
    
    # 删除 systemd 服务文件
    log_info "删除服务文件..."
    rm -f /etc/systemd/system/shadowsocks.service
    rm -f /etc/systemd/system/shadow-tls.service
    systemctl daemon-reload
    
    # 删除二进制文件
    log_info "删除程序文件..."
    rm -f /usr/local/bin/ssserver
    rm -f /usr/local/bin/shadow-tls
    
    # 删除配置文件
    log_info "删除配置文件..."
    rm -rf /etc/shadowsocks
    rm -f /root/ss-tls-config.txt
    
    # 清理防火墙规则（可选）
    read -p "是否清理防火墙规则? [y/N]: " CLEAN_FIREWALL
    if [[ "$CLEAN_FIREWALL" =~ ^[Yy]$ ]]; then
        log_info "清理防火墙规则..."
        
        # 获取之前的端口信息
        if command -v ufw >/dev/null 2>&1; then
            log_warn "请手动删除 ufw 规则: ufw delete allow <端口>"
        elif command -v firewall-cmd >/dev/null 2>&1; then
            log_warn "请手动删除 firewalld 规则: firewall-cmd --permanent --remove-port=<端口>"
        else
            log_warn "请手动检查并清理 iptables 规则"
        fi
    fi
    
    # 清理临时文件
    log_info "清理临时文件..."
    rm -f /tmp/shadowsocks.tar.xz
    rm -f /tmp/shadow-tls*
    
    log_success "卸载完成！"
    echo
    log_info "已删除的内容:"
    echo "- Shadowsocks 服务和配置"
    echo "- Shadow TLS 服务和配置"
    echo "- 所有二进制文件"
    echo "- 配置文件"
    echo
    log_warn "注意: 防火墙规则可能需要手动清理"
}

# 查看配置信息
show_config() {
    if [[ -f /root/ss-tls-config.txt ]]; then
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}         当前配置信息${NC}"
        echo -e "${GREEN}========================================${NC}"
        cat /root/ss-tls-config.txt
    else
        log_error "配置文件不存在，请先安装服务"
    fi
}

# 重启服务
restart_services() {
    log_info "重启服务..."
    
    if systemctl is-enabled shadowsocks >/dev/null 2>&1; then
        systemctl restart shadowsocks
        log_success "Shadowsocks 服务重启完成"
    else
        log_warn "Shadowsocks 服务未安装"
    fi
    
    if systemctl is-enabled shadow-tls >/dev/null 2>&1; then
        systemctl restart shadow-tls
        log_success "Shadow TLS 服务重启完成"
    else
        log_warn "Shadow TLS 服务未安装"
    fi
}

# 查看服务状态
show_status() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}         服务状态${NC}"
    echo -e "${GREEN}========================================${NC}"
    
    if systemctl is-enabled shadowsocks >/dev/null 2>&1; then
        echo -e "\n${YELLOW}Shadowsocks 状态:${NC}"
        systemctl status shadowsocks --no-pager -l
    else
        log_warn "Shadowsocks 服务未安装"
    fi
    
    if systemctl is-enabled shadow-tls >/dev/null 2>&1; then
        echo -e "\n${YELLOW}Shadow TLS 状态:${NC}"
        systemctl status shadow-tls --no-pager -l
    else
        log_warn "Shadow TLS 服务未安装"
    fi
    
    echo -e "\n${YELLOW}端口监听状态:${NC}"
    ss -tulpn | grep -E "(443|ssserver|shadow-tls)" || echo "未发现相关端口监听"
}

# 查看日志
show_logs() {
    echo "请选择要查看的日志:"
    echo "1) Shadowsocks 日志"
    echo "2) Shadow TLS 日志"
    echo "3) 实时日志 (Shadowsocks)"
    echo "4) 实时日志 (Shadow TLS)"
    read -p "请选择 [1-4]: " LOG_CHOICE
    
    case $LOG_CHOICE in
        1)
            journalctl -u shadowsocks --no-pager -l
            ;;
        2)
            journalctl -u shadow-tls --no-pager -l
            ;;
        3)
            log_info "按 Ctrl+C 退出实时日志"
            journalctl -f -u shadowsocks
            ;;
        4)
            log_info "按 Ctrl+C 退出实时日志"
            journalctl -f -u shadow-tls
            ;;
        *)
            log_error "无效选择"
            ;;
    esac
}

# 安装主函数
install_main() {
    check_system
    get_user_input
    install_dependencies
    install_shadowsocks
    install_shadow_tls
    configure_firewall
    start_services
    generate_config
}

# 主菜单循环
main_menu() {
    while true; do
        show_menu
        case $choice in
            1)
                install_main
                read -p "按回车键继续..."
                ;;
            2)
                uninstall_ss_tls
                read -p "按回车键继续..."
                ;;
            3)
                show_config
                read -p "按回车键继续..."
                ;;
            4)
                restart_services
                read -p "按回车键继续..."
                ;;
            5)
                show_status
                read -p "按回车键继续..."
                ;;
            6)
                show_logs
                read -p "按回车键继续..."
                ;;
            7)
                troubleshoot
                read -p "按回车键继续..."
                ;;
            0)
                log_info "退出脚本"
                exit 0
                ;;
            *)
                log_error "无效选择，请重新输入"
                sleep 2
                ;;
        esac
    done
}

# 检查参数
if [[ $# -eq 0 ]]; then
    main_menu
else
    case $1 in
        install)
            install_main
            ;;
        uninstall)
            uninstall_ss_tls
            ;;
        status)
            show_status
            ;;
        config)
            show_config
            ;;
        restart)
            restart_services
            ;;
        *)
            echo "用法: $0 [install|uninstall|status|config|restart]"
            echo "或直接运行 $0 进入交互模式"
            ;;
    esac
fi
