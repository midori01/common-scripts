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
default_snell_version=v4.1.1
if [[ "$(uname -m)" == "x86_64" ]]; then
  snell_type="amd64"
elif [[ "$(uname -m)" == "aarch64" ]]; then
  snell_type="aarch64"
else
  echo "$(uname -m) 架构不支持"
  exit 1
fi

uninstall() {
  systemctl disable snell.service --now
  rm -f /etc/systemd/system/snell.service
  rm -f /etc/snell-server.conf
  rm -f /usr/local/bin/snell-server
  echo "Snell 已卸载"
}

update() {
  local snell_version=${1:-$default_snell_version}
  rm /usr/local/bin/snell-server > /dev/null 2>&1
  wget -N --no-check-certificate https://dl.nssurge.com/snell/snell-server-${snell_version}-linux-${snell_type}.zip > /dev/null 2>&1
  unzip snell-server-${snell_version}-linux-${snell_type}.zip > /dev/null 2>&1
  mv snell-server /usr/local/bin/snell-server > /dev/null 2>&1
  chmod +x /usr/local/bin/snell-server > /dev/null 2>&1
  rm snell-server-${snell_version}-linux-${snell_type}.zip > /dev/null 2>&1
  systemctl restart snell.service > /dev/null 2>&1
  systemctl restart snell2.service > /dev/null 2>&1
  echo "Snell ${snell_version} has been successfully updated."
}

if [[ $1 == "uninstall" ]]; then
  uninstall
  exit 0
fi

if [[ $1 == "update" ]]; then
  if [[ -n $2 ]]; then
    update "$2"
  else
    update
  fi
  exit 0
fi

read -r -p "请输入 Snell 监听端口 (留空默认 6800): " snell_port
snell_port=${snell_port:-6800}
read -r -p "请输入 Snell 密码 (留空随机生成): " snell_password
if [[ -z "$snell_password" ]]; then
  snell_password=$(openssl rand -base64 32)
fi
read -r -p "是否开启 HTTP 混淆 (Y/N 默认不开启): " enable_http_obfs
if [[ ${enable_http_obfs,,} == "y" ]]; then
  snell_obfs="http"
else
  snell_obfs="off"
fi

cat <<EOF
请确认以下配置信息：
端口：${snell_port}
密码：${snell_password}
混淆：${snell_obfs}
EOF
read -r -p "确认无误？(Y/N)" confirm
case "$confirm" in
  [yY]) ;;
  *) echo "已取消安装"; exit 0;;
esac

wget -N --no-check-certificate https://dl.nssurge.com/snell/snell-server-${default_snell_version}-linux-${snell_type}.zip
unzip snell-server-${default_snell_version}-linux-${snell_type}.zip
mv snell-server /usr/local/bin/snell-server
chmod +x /usr/local/bin/snell-server
rm snell-server-${default_snell_version}-linux-${snell_type}.zip

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
obfs = ${snell_obfs}
EOF

systemctl daemon-reload
systemctl enable snell.service --now

echo "Snell 安装成功"
echo "客户端连接信息: "
echo "端口: ${snell_port}"
echo "密码: ${snell_password}"
echo "混淆: ${snell_obfs}"
echo "版本: v4"
