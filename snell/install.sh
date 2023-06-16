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

uninstall() {
  systemctl stop snell.service
  systemctl disable snell.service
  rm -f /etc/systemd/system/snell.service
  rm -f /etc/snell-server.conf
  rm -f /usr/local/bin/snell-server
  echo "Snell 已卸载"
}

update() {
  rm /usr/local/bin/snell-server
  wget -N --no-check-certificate https://dl.nssurge.com/snell/snell-server-${snell_version}-linux-${snell_type}.zip
  unzip snell-server-${snell_version}-linux-${snell_type}.zip
  mv snell-server /usr/local/bin/snell-server
  chmod +x /usr/local/bin/snell-server
  rm snell-server-${snell_version}-linux-${snell_type}.zip
  systemctl restart snell.service
  echo "Snell 已更新"
}

if [[ $1 == "uninstall" ]]; then
  uninstall
  exit 0
fi

if [[ $1 == "update" ]]; then
  update
  exit 0
fi

snell_version=v4.0.1

if [[ "$(uname -m)" == "x86_64" ]]; then
  snell_type="amd64"
elif [[ "$(uname -m)" == "aarch64" ]]; then
  snell_type="aarch64"
else
  echo "$(uname -m) 架构不支持"
  exit 1
fi

read -r -p "请输入 Snell 监听端口 (留空默认 6800): " snell_port
snell_port=${snell_port:-6800}

read -r -p "请输入 Snell 密码 (留空随机生成): " snell_password
if [[ -z "$snell_password" ]]; then
  snell_password=$(openssl rand -base64 32)
fi

cat <<EOF
请确认以下配置信息：
Snell 端口：${snell_port}
Snell 密码：${snell_password}
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
rm snell-server-${snell_version}-linux-${snell_type}.zip

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
listen = ::0:${snell_port}
psk = ${snell_password}
ipv6 = true
obfs = off
EOF

systemctl daemon-reload
systemctl start snell.service
systemctl enable snell.service

echo "Snell 安装成功"
echo "客户端连接信息: "
echo "连接端口: ${shadowtls_port}"
echo "Snell 密码: ${snell_password}"
echo "Snell 混淆: Disabled"
echo "Snell 版本: v4"
