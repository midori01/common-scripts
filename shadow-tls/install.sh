#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi
if ! command -v wget &> /dev/null; then
  echo "wget 未安装，请安装后再运行脚本"
  exit 1
fi
shadowtls_version=$(curl -m 10 -sL "https://api.github.com/repos/ihciah/shadow-tls/releases/latest" | awk -F'"' '/tag_name/{print $4}')
if [[ "$(uname -m)" == "x86_64" ]]; then
  shadowtls_type="x86_64"
elif [[ "$(uname -m)" == "aarch64" ]]; then
  shadowtls_type="aarch64"
else
  echo "$(uname -m) 架构不支持"
  exit 1
fi
uninstall() {
  systemctl stop shadow-tls.service
  systemctl disable shadow-tls.service
  rm -f /etc/systemd/system/shadow-tls.service
  rm -f /etc/shadow-tls.json
  rm -f /usr/local/bin/shadow-tls
  echo "Shadow-TLS 已卸载"
}
update() {
  rm -f /usr/local/bin/shadow-tls
  wget -O /usr/local/bin/shadow-tls "https://github.com/ihciah/shadow-tls/releases/download/${shadowtls_version}/shadow-tls-${shadowtls_type}-unknown-linux-musl"
  chmod +x /usr/local/bin/shadow-tls
  systemctl restart shadow-tls.service
  echo "Shadow-TLS 已更新"
}
if [[ $1 == "uninstall" ]]; then
  uninstall
  exit 0
fi
if [[ $1 == "update" ]]; then
  update
  exit 0
fi
read -r -p "请输入 Shadow-TLS 监听端口 (留空默认 443): " shadowtls_port
shadowtls_port=${shadowtls_port:-443}
read -r -p "请输入 Shadow-TLS 密码 (留空随机生成): " shadowtls_password
if [[ -z "$shadowtls_password" ]]; then
  shadowtls_password=$(openssl rand -base64 32)
fi
read -r -p "请输入 Shadow-TLS SNI (留空默认 www.iq.com): " sni_domain
sni_domain=${sni_domain:-www.iq.com}
read -r -p "请输入本机其他 TCP 代理协议端口: " server_port
cat <<EOF
请确认以下配置信息：
Shadow-TLS 端口：${shadowtls_port}
Shadow-TLS 密码：${shadowtls_password}
Shadow-TLS SNI：${sni_domain}
其他 TCP 协议端口：${server_port}
EOF
read -r -p "确认无误？(Y/N)" confirm
case "$confirm" in
  [yY]) ;;
  *) echo "已取消安装"; exit 0;;
esac
wget -O /usr/local/bin/shadow-tls "https://github.com/ihciah/shadow-tls/releases/download/${shadowtls_version}/shadow-tls-${shadowtls_type}-unknown-linux-musl"
chmod +x /usr/local/bin/shadow-tls
cat > /etc/systemd/system/shadow-tls.service <<EOF
[Unit]
Description=shadow-tls service
After=network.target

[Service]
Type=simple
User=root
Group=nogroup
LimitNOFILE=32768
ExecStart=/usr/local/bin/shadow-tls config --config /etc/shadow-tls.json
StandardOutput=null
StandardError=null
SyslogIdentifier=shadow-tls
Environment=MONOIO_FORCE_LEGACY_DRIVER=1

[Install]
WantedBy=multi-user.target
EOF
cat > /etc/shadow-tls.json <<EOF
{
  "disable_nodelay": false,
  "fastopen": true,
  "v3": true,
  "strict": true,
  "server": {
    "listen": "[::]:${shadowtls_port}",
    "server_addr": "127.0.0.1:${server_port}",
    "tls_addr": {
      "wildcard_sni": "off",
      "dispatch": {
        "cloudflare.com": "1.1.1.1:443",
        "captive.apple.com": "captive.apple.com:443"
      },
      "fallback": "${sni_domain}:443"
    },
    "password": "${shadowtls_password}",
    "wildcard_sni": "authed"
  }
}
EOF
systemctl daemon-reload
systemctl start shadow-tls.service
systemctl enable shadow-tls.service
echo "Shadow-TLS 安装成功"
echo "客户端连接信息: "
echo "连接端口: ${shadowtls_port}"
echo "Shadow-TLS 密码: ${shadowtls_password}"
echo "Shadow-TLS SNI: ${sni_domain}"
echo "Shadow-TLS 版本: v3"
