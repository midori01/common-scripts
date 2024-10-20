#!/bin/bash

check_system() { [[ $EUID != 0 ]] && { echo "请以 root 权限运行脚本"; exit 1; }; grep -qiE "debian|ubuntu" /etc/issue || { echo "仅支持 Debian 或 Ubuntu 系统"; exit 1; }; deps=(curl wget openssl jq); for dep in "${deps[@]}"; do command -v "$dep" &> /dev/null || missing_deps+=("$dep"); done; [[ ${#missing_deps[@]} -ne 0 ]] && apt install -y "${missing_deps[@]}"; }
download_ss() { arch=$(uname -m); version=$(curl -s https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest | jq -r '.tag_name'); wget -qO- "https://github.com/shadowsocks/shadowsocks-rust/releases/download/${version}/shadowsocks-${version}.${arch}-unknown-linux-gnu.tar.xz" | tar -xJ -C /tmp && mv /tmp/ssserver /usr/local/bin/ss-rust && chmod +x /usr/local/bin/ss-rust && rm -f /tmp/ss* && echo "$version" || { echo "下载或解压失败"; return 1; }; }
set_config() { read -p "请输入端口号 [默认: 8964]：" server_port; server_port=${server_port:-8964}; while ! [[ $server_port =~ ^[0-9]+$ && $server_port -ge 1 && $server_port -le 65535 ]]; do read -p "无效端口号，请输入 (1-65535)：" server_port; done; PS3="请选择加密方式 [默认: none]："; options=("aes-128-gcm" "aes-256-gcm" "chacha20-ietf-poly1305" "2022-blake3-aes-128-gcm" "2022-blake3-aes-256-gcm" "none"); select method in "${options[@]}"; do method=${method:-"none"}; break; done; password=$( [[ "$method" == "none" ]] && echo "" || openssl rand -base64 $( [[ "$method" =~ "aes-128" ]] && echo 16 || echo 32 )); }
create_json() { echo -e "[Unit]\nDescription=Shadowsocks Rust\nAfter=network-online.target\n\n[Service]\nType=simple\nUser=root\nLimitNOFILE=102400\nRestart=on-failure\nRestartSec=5s\nExecStart=/usr/local/bin/ss-rust -c /etc/ss-rust.json\n\n[Install]\nWantedBy=multi-user.target" > /etc/systemd/system/ss-rust.service; cat > /etc/ss-rust.json <<-EOF
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
    systemctl enable --now ss-rust && systemctl restart ss-rust; }
modify_json() { [[ -f /etc/ss-rust.json ]] && jq '. + {plugin: "obfs-server", plugin_opts: "obfs=http", server: "0.0.0.0"}' /etc/ss-rust.json > /etc/ss-rust.json.tmp && mv /etc/ss-rust.json.tmp /etc/ss-rust.json && systemctl restart ss-rust && echo "配置文件已修改，Shadowsocks Rust 重启完成" || echo "配置文件不存在，请先安装 Shadowsocks Rust"; }
check_system
case "$1" in
    update) version=$(download_ss) && systemctl restart ss-rust && echo "Shadowsocks Rust ${version} 更新完成" || echo "更新失败" ;;
    uninstall) systemctl disable --now ss-rust && rm -f /usr/local/bin/ss-rust /etc/ss-rust.json /etc/systemd/system/ss-rust.service && systemctl daemon-reload && echo "Shadowsocks Rust 卸载完成" ;;
    obfs) apt update > /dev/null 2>&1 && apt install --no-install-recommends -y build-essential autoconf libtool libssl-dev libpcre3-dev libev-dev asciidoc xmlto automake git > /dev/null 2>&1 && git clone https://github.com/shadowsocks/simple-obfs.git > /dev/null 2>&1 && cd simple-obfs && echo "正在初始化子模块并编译安装 simple-obfs，请耐心等待..." && git submodule update --init --recursive > /dev/null 2>&1 && ./autogen.sh > /dev/null 2>&1 && ./configure > /dev/null 2>&1 && make > /dev/null 2>&1 && make install > /dev/null 2>&1 && echo "simple-obfs 安装完成" && modify_json || echo "simple-obfs 安装失败" && cd .. && rm -rf simple-obfs ;;
    *) download_ss && set_config && create_json && echo "安装完成，端口: ${server_port}, 加密: ${method}, 密码: ${password}" ;;
esac