#!/bin/bash

check_root() {
    [[ $EUID != 0 ]] && echo "请以 root 权限运行脚本" && exit 1
}

check_sys() {
    if ! grep -qi "debian" /etc/issue && ! grep -qi "ubuntu" /etc/issue; then
        echo "仅支持 Debian 或 Ubuntu 系统" && exit 1
    fi
}

check_dependencies() {
    local dependencies=("curl" "wget" "openssl")
    local missing_dependencies=()
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_dependencies+=("$dep")
        fi
    done
    if [ ${#missing_dependencies[@]} -ne 0 ]; then
        echo "缺少依赖：${missing_dependencies[*]}"
        echo "正在安装依赖..."
        apt install -y "${missing_dependencies[@]}" || { echo "依赖安装失败"; exit 1; }
    fi
}

get_latest_version() {
    local version
    version=$(curl -s https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    echo "$version"
}

download_ss_rust() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        "x86_64") arch="x86_64" ;;
        "aarch64") arch="aarch64" ;;
        *) echo "不支持的架构: $arch" && return 1 ;;
    esac
    local version
    version=$(get_latest_version)
    if [[ -z "$version" ]]; then
        echo "获取版本号失败，请检查网络或 GitHub API 状态"
        return 1
    fi
    wget "https://github.com/shadowsocks/shadowsocks-rust/releases/download/${version}/shadowsocks-${version}.${arch}-unknown-linux-gnu.tar.xz" -q
    if [[ $? -ne 0 ]]; then
        echo "Shadowsocks Rust 下载失败，请检查网络"
        return 1
    fi
    tar -xf "shadowsocks-${version}.${arch}-unknown-linux-gnu.tar.xz" -C /tmp/ && mv /tmp/ssserver /usr/local/bin/ss-rust
    chmod +x /usr/local/bin/ss-rust
    rm "shadowsocks-${version}.${arch}-unknown-linux-gnu.tar.xz" 2>/dev/null || true
    echo "$version"
}

update_ss_rust() {
    rm -f /usr/local/bin/ss-rust
    local version
    if ! version=$(download_ss_rust); then
        echo "ss-rust update failed."
        return 1
    fi
    systemctl restart ss-rust > /dev/null 2>&1
    echo "ss-rust ${version} has been successfully updated."
}

generate_password() {
    if [[ "${method}" == "none" ]]; then
        password=""
    elif [[ "${method}" == "2022-blake3-aes-128-gcm" ]]; then
        password=$(openssl rand -base64 16)
    else
        password=$(openssl rand -base64 32)
    fi
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
    read -p "请输入数字选择加密方式 [默认: 7]：" method_num
    method_num=${method_num:-7}
    method=${options[$((method_num - 1))]:-"none"}
}

write_config() {
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
}

create_service() {
    if [[ ! -f /usr/local/bin/ss-rust ]]; then
        exit 1
    fi
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
    systemctl enable --now ss-rust > /dev/null 2>&1 && systemctl restart ss-rust > /dev/null 2>&1
}

uninstall_ss_rust() {
    systemctl disable --now ss-rust > /dev/null 2>&1
    rm -f /usr/local/bin/ss-rust /etc/ss-rust.json /etc/systemd/system/ss-rust.service
    systemctl daemon-reload > /dev/null 2>&1
    echo "Shadowsocks Rust 卸载完成"
}

simple_obfs() {
    apt update > /dev/null 2>&1
    apt install --no-install-recommends -y build-essential autoconf libtool libssl-dev libpcre3-dev libev-dev asciidoc xmlto automake > /dev/null 2>&1
    git clone https://github.com/shadowsocks/simple-obfs.git > /dev/null 2>&1
    cd simple-obfs || return 1
    if git submodule update --init --recursive > /dev/null 2>&1 && ./autogen.sh > /dev/null 2>&1 && ./configure > /dev/null 2>&1 && make > /dev/null 2>&1 && make install > /dev/null 2>&1; then
        echo "simple-obfs 安装完成"
    else
        echo "simple-obfs 安装失败"
        return 1
    fi
    cd .. && rm -rf simple-obfs
}

check_root
check_sys
check_dependencies

case "$1" in
    update)
        update_ss_rust
        ;;
    uninstall)
        uninstall_ss_rust
        ;;
    obfs)
        simple_obfs
        ;;
    *)
        set_port_method
        generate_password
        download_ss_rust
        write_config
        create_service
        echo "Shadowsocks Rust 安装完成"
        echo "端口: ${server_port}"
        echo "加密: ${method}"
        if [[ -n "${password}" ]]; then
            echo "密码: ${password}"
        fi
        ;;
esac