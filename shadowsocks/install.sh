#!/bin/bash

check_system() { [[ $EUID != 0 ]] && { echo "请以 root 权限运行脚本"; exit 1; }; grep -qiE "debian|ubuntu" /etc/issue || { echo "仅支持 Debian 或 Ubuntu 系统"; exit 1; }; arch=$(uname -m); [[ "$arch" =~ ^(x86_64|aarch64)$ ]] || { echo "架构不支持"; exit 1; }; deps=(curl wget xz openssl jq); for dep in "${deps[@]}"; do command -v "$dep" &> /dev/null || missing_deps+=("$dep"); done; [[ ${#missing_deps[@]} -ne 0 ]] && apt install -y "${missing_deps[@]}"; repo_version="shadowsocks"; }
set_variable() { read -p "请输入端口号 [默认: 8964]：" server_port; server_port=${server_port:-8964}; while ! [[ $server_port =~ ^[0-9]+$ && $server_port -ge 1 && $server_port -le 65535 ]]; do read -p "无效端口号，请输入 (1-65535)：" server_port; done; PS3="请选择加密方式 [默认: none]："; options=("aes-128-gcm" "aes-256-gcm" "chacha20-ietf-poly1305" "rc4-md5" "2022-blake3-aes-128-gcm" "2022-blake3-aes-256-gcm" "2022-blake3-chacha20-poly1305" "none"); select method in "${options[@]}"; do method=${method:-"none"}; break; done; password=$( [[ "$method" == "none" ]] && echo "" || openssl rand -base64 $( [[ "$method" == "2022-blake3-aes-128-gcm" ]] && echo 16 || echo 32 )); }
download_ss() { version=$(curl -s https://api.github.com/repos/${repo_version}/shadowsocks-rust/releases/latest | jq -r '.tag_name'); wget -qO- "https://github.com/${repo_version}/shadowsocks-rust/releases/download/${version}/shadowsocks-${version}.${arch}-unknown-linux-musl.tar.xz" | tar -xJ -C /tmp && mv /tmp/ssserver /usr/local/bin/ssserver && chmod +x /usr/local/bin/ssserver && rm -f /tmp/ss* && echo "${version}" || { echo "下载或解压失败"; return 1; }; }
modify_json() { [[ -f /etc/ss-rust.json ]] && jq '. + {plugin: "obfs-server", plugin_opts: "obfs=http", server: "0.0.0.0"}' /etc/ss-rust.json > /etc/ss-rust.json.tmp && mv /etc/ss-rust.json.tmp /etc/ss-rust.json && systemctl restart ss-rust && echo -e "配置文件已修改，shadowsocks-rust 重启完成\n端口: $(jq -r '.server_port' /etc/ss-rust.json)\n加密: $(jq -r '.method' /etc/ss-rust.json)\n密码: $(jq -r '.password' /etc/ss-rust.json)\nOBFS 类型: HTTP\nOBFS 域名: 随意填写" || echo "配置文件不存在，请先安装 shadowsocks-rust"; }
create_json() { echo -e "[Unit]\nDescription=shadowsocks-rust\nAfter=network-online.target\n\n[Service]\nType=simple\nUser=root\nLimitNOFILE=102400\nRestart=on-failure\nRestartSec=5s\nExecStart=/usr/local/bin/ssserver -c /etc/ss-rust.json\n\n[Install]\nWantedBy=multi-user.target" > /etc/systemd/system/ss-rust.service; cat > /etc/ss-rust.json <<-EOF
{
  "server": "::",
  "server_port": ${server_port},
  "method": "${method}",
  "password": "${password}",
  "mode": "tcp_and_udp",
  "fast_open": true,
  "no_delay": true,
  "reuse_port": true,
  "ipv6_first": false
}
EOF
}
check_system
case "$1" in
    update) [[ "$2" == "full-extra" ]] && repo_version="midori01"; version=$(download_ss) && systemctl restart ss-rust && echo "shadowsocks-rust ${version} 更新完成" || echo "shadowsocks-rust 更新失败";;
    uninstall) systemctl disable --now ss-rust > /dev/null 2>&1 && rm -f /usr/local/bin/ssserver /etc/ss-rust.json /etc/systemd/system/ss-rust.service /usr/local/bin/obfs-server /usr/local/bin/obfs-local && systemctl daemon-reload && echo "shadowsocks-rust 卸载完成" ;;
    obfs) wget -qO /usr/local/bin/obfs-server "https://github.com/midori01/simple-obfs/releases/download/v1.0.3-midori-build/obfs-server-${arch}" && chmod +x /usr/local/bin/obfs-server && echo "obfs-server 安装完成" && modify_json || echo "obfs-server 安装失败" ;;
    *) set_variable && download_ss && create_json && systemctl enable --now ss-rust > /dev/null 2>&1 && systemctl restart ss-rust && echo -e "shadowsocks-rust 安装完成\n端口: ${server_port}\n加密: ${method}\n密码: ${password}" ;;
esac