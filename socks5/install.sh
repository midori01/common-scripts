#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi
if ! command -v wget &> /dev/null; then
  echo "wget 未安装，请安装后再运行脚本"
  exit 1
fi
if ! command -v gzip &> /dev/null; then
  echo "gzip 未安装，请安装后再运行脚本"
  exit 1
fi
if [[ "$(uname -m)" == "x86_64" ]]; then
  type="amd64"
elif [[ "$(uname -m)" == "aarch64" ]]; then
  type="armv8"
else
  echo "$(uname -m) 架构不支持"
  exit 1
fi
uninstall() {
  systemctl stop socks5.service
  systemctl disable socks5.service
  rm -f /etc/systemd/system/socks5.service
  rm -f /usr/local/bin/gost
  echo "已卸载"
}
tls() {
  read -r -p "请输入 SOCKS5-TLS 监听端口 (留空默认 1080): " socks5_port
socks5_port=${socks5_port:-1080}
  read -r -p "请输入 SOCKS5-TLS 用户名 (留空随机生成): " socks5_username
  if [[ -z "$socks5_username" ]]; then
    socks5_username=$(openssl rand -hex 8)
  fi
  read -r -p "请输入 SOCKS5-TLS 密码 (留空随机生成): " socks5_password
  if [[ -z "$socks5_password" ]]; then
    socks5_password=$(openssl rand -hex 16)
  fi
  read -r -p "请输入证书文件路径: " cer_path
  read -r -p "请输入私钥文件路径: " key_path
  cat <<EOF
请确认以下配置信息：
端口：${socks5_port}
用户：${socks5_username}
密码：${socks5_password}
证书路径：${cer_path}
私钥路径：${key_path}
EOF
  read -r -p "确认无误？(Y/N)" confirm
  case "$confirm" in
    [yY]) ;;
    *) echo "已取消安装"; exit 0;;
  esac
  wget -N --no-check-certificate https://github.com/ginuerzh/gost/releases/download/v2.11.5/gost-linux-${type}-2.11.5.gz
  gzip -d gost-linux-${type}-2.11.5.gz
  mv gost-linux-${type}-2.11.5 /usr/local/bin/gost
  chmod +x /usr/local/bin/gost
  cat > /etc/systemd/system/socks5.service <<EOF
[Unit]
Description=SOCKS5 Proxy Service
After=network.target

[Service]
Type=simple
User=root
Group=nogroup
LimitNOFILE=32768
ExecStart=/usr/local/bin/gost -L "socks5+tls://${socks5_username}:${socks5_password}@:${socks5_port}?udp=true&bind=true&cert=${cer_path}&key=${key_path}"
StandardOutput=null
StandardError=null
SyslogIdentifier=socks5-server

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl start socks5.service
  systemctl enable socks5.service
  echo "SOCKS5-TLS 安装成功"
  echo "客户端连接信息: "
  echo "端口: ${socks5_port}"
  echo "用户: ${socks5_username}"
  echo "密码: ${socks5_password}"
}
if [[ $1 == "uninstall" ]]; then
  uninstall
  exit 0
fi
if [[ $1 == "tls" ]]; then
  tls
  exit 0
fi
read -r -p "请输入 SOCKS5 监听端口 (留空默认 1080): " socks5_port
socks5_port=${socks5_port:-1080}
read -r -p "请输入 SOCKS5 用户名 (留空随机生成): " socks5_username
if [[ -z "$socks5_username" ]]; then
  socks5_username=$(openssl rand -hex 8)
fi
read -r -p "请输入 SOCKS5 密码 (留空随机生成): " socks5_password
if [[ -z "$socks5_password" ]]; then
  socks5_password=$(openssl rand -hex 16)
fi
cat <<EOF
请确认以下配置信息：
端口：${socks5_port}
用户：${socks5_username}
密码：${socks5_password}
EOF
read -r -p "确认无误？(Y/N)" confirm
case "$confirm" in
  [yY]) ;;
  *) echo "已取消安装"; exit 0;;
esac
wget -N --no-check-certificate https://github.com/ginuerzh/gost/releases/download/v2.11.5/gost-linux-${type}-2.11.5.gz
gzip -d gost-linux-${type}-2.11.5.gz
mv gost-linux-${type}-2.11.5 /usr/local/bin/gost
chmod +x /usr/local/bin/gost
cat > /etc/systemd/system/socks5.service <<EOF
[Unit]
Description=SOCKS5 Proxy Service
After=network.target

[Service]
Type=simple
User=root
Group=nogroup
LimitNOFILE=32768
ExecStart=/usr/local/bin/gost -L "socks5://${socks5_username}:${socks5_password}@:${socks5_port}?udp=true&bind=true"
StandardOutput=null
StandardError=null
SyslogIdentifier=socks5-server

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl start socks5.service
systemctl enable socks5.service
echo "SOCKS5 安装成功"
echo "客户端连接信息: "
echo "端口: ${socks5_port}"
echo "用户: ${socks5_username}"
echo "密码: ${socks5_password}"
