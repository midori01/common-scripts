#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi
if ! command -v wget &> /dev/null; then
  echo "wget 未安装，请安装后再运行脚本"
  exit 1
fi
if ! command -v unzip &> /dev/null; then
  echo "unzip 未安装，请安装后再运行脚本"
  exit 1
fi

snell_version=v4.0.1
shadowtls_version=$(curl -m 10 -sL "https://api.github.com/repos/ihciah/shadow-tls/releases/latest" | awk -F'"' '/tag_name/{print $4}')
if [[ "$(uname -m)" == "x86_64" ]]; then
  snell_type="amd64"
  shadowtls_type="x86_64"
elif [[ "$(uname -m)" == "aarch64" ]]; then
  snell_type="aarch64"
  shadowtls_type="aarch64"
else
  echo "$(uname -m) 架构不支持"
  exit 1
fi

uninstall() {
  systemctl stop snell.service
  systemctl stop shadow-tls.service
  systemctl disable snell.service
  systemctl disable shadow-tls.service
  rm -f /etc/systemd/system/snell.service
  rm -f /etc/systemd/system/shadow-tls.service
  rm -f /etc/snell-server.conf
  rm -f /etc/shadow-tls.json
  rm -f /usr/local/bin/snell-server
  rm -f /usr/local/bin/shadow-tls
  echo "Snell + Shadow-TLS 已卸载"
}

update() {
  rm -f /usr/local/bin/snell-server
  rm -f /usr/local/bin/shadow-tls
  wget -N --no-check-certificate https://dl.nssurge.com/snell/snell-server-${snell_version}-linux-${snell_type}.zip
  unzip snell-server-${snell_version}-linux-${snell_type}.zip
  mv snell-server /usr/local/bin/snell-server
  chmod +x /usr/local/bin/snell-server
  rm -f snell-server-${snell_version}-linux-${snell_type}.zip
  wget -O /usr/local/bin/shadow-tls "https://github.com/ihciah/shadow-tls/releases/download/${shadowtls_version}/shadow-tls-${shadowtls_type}-unknown-linux-musl"
  chmod +x /usr/local/bin/shadow-tls
  systemctl restart snell.service
  systemctl restart shadow-tls.service
  echo "Snell + Shadow-TLS 已更新"
}

if [[ $1 == "uninstall" ]]; then
  uninstall
  exit 0
fi
if [[ $1 == "update" ]]; then
  update
  exit 0
fi

read -r -p "请输入 Snell 监听端口 (留空默认 6800): " snell_port
snell_port=${snell_port:-6800}

read -r -p "请输入 Snell 密码 (留空随机生成): " snell_password
if [[ -z "$snell_password" ]]; then
  snell_password=$(openssl rand -base64 32)
fi

read -r -p "请输入 Shadow-TLS 监听端口 (留空默认 443): " shadowtls_port
shadowtls_port=${shadowtls_port:-443}

read -r -p "请输入 Shadow-TLS 密码 (留空随机生成): " shadowtls_password
if [[ -z "$shadowtls_password" ]]; then
  shadowtls_password=$(openssl rand -base64 32)
fi

read -r -p "请输入 Shadow-TLS SNI (留空默认 www.iq.com): " sni_domain
sni_domain=${sni_domain:-www.iq.com}

cat <<EOF
请确认以下配置信息：
Snell 端口：${snell_port}
Snell 密码：${snell_password}
Shadow-TLS 端口：${shadowtls_port}
Shadow-TLS 密码：${shadowtls_password}
Shadow-TLS SNI：${sni_domain}
EOF
read -r -p "确认无误？(Y/N)" confirm
case "$confirm" in
  [yY]) ;;
  *) echo "已取消安装"; exit 0;;
esac

wget -N --no-check-certificate https://dl.nssurge.com/snell/snell-server-${snell_version}-linux-${snell_type}.zip
unzip snell-server-${snell_version}-linux-${snell_type}.zip
mv snell-server /usr/local/bin/snell-server
chmod +x /usr/local/bin/snell-server
rm -f snell-server-${snell_version}-linux-${snell_type}.zip

cat > /etc/systemd/system/snell.service <<EOF
[Unit]
Description=Snell Proxy Service
After=network.target

[Service]
Type=simple
User=root
Group=nogroup
LimitNOFILE=32768
ExecStart=/usr/local/bin/snell-server -c /etc/snell-server.conf
StandardOutput=null
StandardError=null
SyslogIdentifier=snell-server

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/snell-server.conf <<EOF
[snell-server]
listen = 127.0.0.1:${snell_port}
psk = ${snell_password}
ipv6 = true
obfs = off
EOF

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
    "server_addr": "127.0.0.1:${snell_port}",
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
systemctl start snell.service
systemctl start shadow-tls.service
systemctl enable snell.service
systemctl enable shadow-tls.service

echo "Snell + Shadow-TLS 安装成功"
echo "客户端连接信息: "
echo "连接端口: ${shadowtls_port}"
echo "Snell 密码: ${snell_password}"
echo "Snell 混淆: Disabled"
echo "Snell 版本: v4"
echo "Shadow-TLS 密码: ${shadowtls_password}"
echo "Shadow-TLS SNI: ${sni_domain}"
echo "Shadow-TLS 版本: v3"
