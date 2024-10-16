#!/usr/bin/env bash

Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"

check_root(){
    [[ $EUID != 0 ]] && echo -e "${Error} 请以 root 权限运行此脚本" && exit 1
}

check_sys(){
    if ! grep -qi "debian" /etc/issue && ! grep -qi "ubuntu" /etc/issue; then
        echo -e "${Error} 系统不支持，仅支持 Debian 或 Ubuntu 系统" && exit 1
    fi
}

check_dependencies(){
    local dependencies=("curl" "wget" "xz-utils" "openssl")
    local missing_dependencies=()
    
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_dependencies+=("$dep")
        fi
    done
    
    if [ ${#missing_dependencies[@]} -ne 0 ]; then
        echo -e "${Error} 缺少以下依赖：${missing_dependencies[*]}"
        echo -e "请运行以下命令安装依赖："
        echo -e "apt install -y ${missing_dependencies[*]}"
        exit 1
    fi
}

generate_password(){
    if [[ "${method}" == "none" ]]; then
        password=""
    elif [[ "${method}" == "2022-blake3-aes-128-gcm" ]]; then
        password=$(openssl rand -base64 16)
    else
        password=$(openssl rand -base64 32)
    fi
}

set_port_method(){
    read -p "请输入端口号 [默认: 8964]：" server_port
    server_port=${server_port:-8964}

    echo -e "${Info} 请选择加密方式："
    options=("aes-128-gcm" "aes-256-gcm" "chacha20-ietf-poly1305" "2022-blake3-aes-128-gcm" "2022-blake3-aes-256-gcm" "2022-blake3-chacha20-ietf-poly1305" "none")
    
    for i in "${!options[@]}"; do
        echo -e "$((i + 1)). ${options[i]}"
    done
    
    read -p "请输入数字选择加密方式 [默认: 7]：" method_num
    method_num=${method_num:-7}

    method=${options[$((method_num - 1))]:-"none"}
}

download_ss_rust(){
    local arch
    arch=$(uname -m)
    case "$arch" in
        "x86_64") arch="x86_64" ;;
        "aarch64") arch="aarch64" ;;
        *) echo -e "${Error} 不支持的架构: $arch" && exit 1 ;;
    esac

    local version
    version=$(curl -s https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    wget "https://github.com/shadowsocks/shadowsocks-rust/releases/download/${version}/shadowsocks-${version}.${arch}-unknown-linux-gnu.tar.xz"

    tar -xvf "shadowsocks-${version}.${arch}-unknown-linux-gnu.tar.xz"
    mv ssserver /usr/local/bin/ss-rust
    chmod +x /usr/local/bin/ss-rust
    rm "shadowsocks-${version}.${arch}-unknown-linux-gnu.tar.xz" # 删除下载的压缩包
}

write_config(){
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
    "ipv6_first": false,
    "user": "root",
    "timeout": 3600
}
EOF
}

create_service(){
    cat > /etc/systemd/system/ss-rust.service <<-EOF
[Unit]
Description= Shadowsocks Rust
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service
[Service]
LimitNOFILE=102400
Type=simple
User=root
Restart=on-failure
RestartSec=5s
DynamicUser=true
ExecStartPre=/bin/sh -c ulimit -n 102400
ExecStart=/usr/local/bin/ss-rust -c /etc/ss-rust.json
[Install]
WantedBy=multi-user.target
EOF
    systemctl enable --now ss-rust
}

uninstall_ss_rust(){
    systemctl disable --now ss-rust
    rm -f /usr/local/bin/ss-rust
    rm -f /etc/ss-rust.json
    rm -f /etc/systemd/system/ss-rust.service
    systemctl daemon-reload
    echo -e "${Info} Shadowsocks Rust 已卸载"
}

update_ss_rust(){
    rm -f /usr/local/bin/ss-rust
    download_ss_rust
    systemctl restart ss-rust
    echo -e "${Info} Shadowsocks Rust 已更新至最新版本"
}

simple_obfs() {
    echo -e "${Info} 正在编译安装 simple-obfs"
    local dependencies=("build-essential" "autoconf" "libtool" "libssl-dev" "libpcre3-dev" "libev-dev" "asciidoc" "xmlto" "automake")
    apt update
    apt install --no-install-recommends -y "${dependencies[@]}"
    
    git clone https://github.com/shadowsocks/simple-obfs.git
    cd simple-obfs || return 1

    if git submodule update --init --recursive && ./autogen.sh && ./configure && make && make install; then
        echo -e "${Info} simple-obfs 安装完成"
        obfs-server -h
    else
        echo -e "${Error} simple-obfs 安装失败"
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
        echo -e "${Info} Shadowsocks Rust 安装完成并启动"
        echo -e "${Info} 端口: ${server_port}"
        echo -e "${Info} 加密: ${method}"
        if [[ -n "${password}" ]]; then
            echo -e "${Info} 密码: ${password}"
        fi
        ;;
esac