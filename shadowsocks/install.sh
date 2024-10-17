#!/bin/bash

check_root() {
    [[ $EUID != 0 ]] && echo "请以 root 权限运行脚本" && exit 1
}

check_sys() {
    grep -qiE "debian|ubuntu" /etc/issue || { echo "仅支持 Debian 或 Ubuntu 系统"; exit 1; }
}

check_dependencies() {
    local dependencies=("curl" "wget" "openssl")
    for dep in "${dependencies[@]}"; do
        command -v "$dep" &> /dev/null || missing_deps+=("$dep")
    done
    [[ ${#missing_deps[@]} -ne 0 ]] && apt install -y "${missing_deps[@]}"
}

download_ss_rust() {
    local arch version
    arch=$(uname -m)
    version=$(curl -s https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    [[ -z "$version" ]] && echo "获取版本号失败" && return 1
    wget "https://github.com/shadowsocks/shadowsocks-rust/releases/download/${version}/shadowsocks-${version}.${arch}-unknown-linux-gnu.tar.xz" -q || { echo "下载失败"; return 1; }
    tar -xf "shadowsocks-${version}.${arch}-unknown-linux-gnu.tar.xz" -C /tmp/ \
        && mv /tmp/ssserver /usr/local/bin/ss-rust \
        && chmod +x /usr/local/bin/ss-rust \
        && rm "shadowsocks-${version}.${arch}-unknown-linux-gnu.tar.xz"
    echo "$version"
}

set_port_method() {
    while true; do
        read -p "请输入端口号 [默认: 8964]：" server_port
        server_port=${server_port:-8964}
        if [[ "$server_port" =~ ^[0-9]+$ ]] && [ "$server_port" -ge 1 ] && [ "$server_port" -le 65535 ]; then
            break
        else
            echo "无效端口号，请输入一个有效的端口号 (1-65535)"
        fi
    done
    echo "请选择加密方式："
    options=("aes-128-gcm" "aes-256-gcm" "chacha20-ietf-poly1305" "2022-blake3-aes-128-gcm" "2022-blake3-aes-256-gcm" "2022-blake3-chacha20-ietf-poly1305" "none")
    for i in "${!options[@]}"; do
        echo "$((i + 1)). ${options[i]}"
    done
    while true; do
        read -p "请输入数字选择加密方式 [默认: 7 (none)]：" method_num
        if [[ -z "$method_num" ]]; then
            method="none"
            break
        elif [[ "$method_num" =~ ^[1-7]$ ]]; then
            method=${options[$((method_num - 1))]:-"none"}
            break
        else
            echo "无效选择，请输入 1-7 的数字"
        fi
    done
}

generate_password() {
    [[ "$method" == "none" ]] && password="" || password=$(openssl rand -base64 $( [[ "$method" =~ "aes-128" ]] && echo 16 || echo 32 ))
}

setup_service() {
    cat > /etc/ss-rust.json <<-EOF
{
    "server": "::",
    "server_port": ${server_port},
    "method": "${method}",
    "password": "${password}",
    "mode": "tcp_and_udp",
    "fast_open": true,
    "no_delay": true,
    "reuse_port": true,
    "nameserver": "1.1.1.1",
    "ipv6_first": false,
    "user": "root",
    "timeout": 3600
}
EOF

    cat > /etc/systemd/system/ss-rust.service <<-EOF
[Unit]
Description=Shadowsocks Rust
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service
[Service]
LimitNOFILE=102400
Type=simple
User=root
Restart=on-failure
RestartSec=5s
ExecStartPre=/bin/sh -c ulimit -n 102400
ExecStart=/usr/local/bin/ss-rust -c /etc/ss-rust.json
[Install]
WantedBy=multi-user.target
EOF

    systemctl enable --now ss-rust > /dev/null 2>&1
    systemctl restart ss-rust > /dev/null 2>&1
}

check_root
check_sys
check_dependencies

case "$1" in
    update)
        version=$(download_ss_rust)
        if [[ $? -eq 0 ]]; then
            systemctl restart ss-rust > /dev/null 2>&1
            echo "Shadowsocks Rust ${version} 更新完成"
        else
            echo "Shadowsocks Rust 更新失败"
        fi
        ;;
    uninstall)
        systemctl disable --now ss-rust > /dev/null 2>&1
        rm -f /usr/local/bin/ss-rust /etc/ss-rust.json /etc/systemd/system/ss-rust.service
        systemctl daemon-reload > /dev/null 2>&1
        echo "Shadowsocks Rust 卸载完成"
        ;;
    obfs)
        apt update > /dev/null 2>&1
        apt install --no-install-recommends -y build-essential autoconf libtool libssl-dev libpcre3-dev libev-dev asciidoc xmlto automake > /dev/null 2>&1
        git clone https://github.com/shadowsocks/simple-obfs.git > /dev/null 2>&1
        cd simple-obfs || exit 1
        if git submodule update --init --recursive > /dev/null 2>&1 && ./autogen.sh > /dev/null 2>&1 && ./configure > /dev/null 2>&1 && make > /dev/null 2>&1 && make install > /dev/null 2>&1; then
            echo "simple-obfs 安装完成"
        else
            echo "simple-obfs 安装失败"
        fi
        cd .. && rm -rf simple-obfs
        ;;
    *)
        set_port_method
        generate_password
        download_ss_rust
        setup_service
        echo "Shadowsocks Rust 安装完成"
        echo -e "端口: ${server_port}\n加密: ${method}\n密码: ${password}"
        ;;
esac