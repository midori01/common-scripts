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
latest_version=$(curl -m 10 -sL "https://api.github.com/repos/ginuerzh/gost/releases/latest" | awk -F'"' '/tag_name/{gsub(/v/, "", $4); print $4}')
uninstall() {
  systemctl stop gost.service
  systemctl disable gost.service
  rm -f /etc/systemd/system/gost.service
  rm -f /usr/local/bin/gost
  echo "GOST 已卸载"
}
update() {
  rm -f /usr/local/bin/gost
  wget -N --no-check-certificate https://github.com/ginuerzh/gost/releases/download/v${latest_version}/gost-linux-${type}-${latest_version}.gz
  gzip -d gost-linux-${type}-${latest_version}.gz
  mv gost-linux-${type}-${latest_version} /usr/local/bin/gost
  chmod +x /usr/local/bin/gost
  systemctl restart gost.service
  echo "GOST 已更新"
}
socks5() {
  read -r -p "请输入 SOCKS5 监听端口 (留空默认 1080): " gost_port
  gost_port=${gost_port:-1080}
  read -r -p "请输入 SOCKS5 用户名 (留空随机生成): " gost_username
  if [[ -z "$gost_username" ]]; then
    gost_username=$(openssl rand -hex 8)
  fi
  read -r -p "请输入 SOCKS5 密码 (留空随机生成): " gost_password
  if [[ -z "$gost_password" ]]; then
    gost_password=$(openssl rand -hex 16)
  fi
  cat <<EOF
请确认以下配置信息：
协议：SOCKS5
端口：${gost_port}
用户：${gost_username}
密码：${gost_password}
EOF
  read -r -p "确认无误？(Y/N)" confirm
  case "$confirm" in
    [yY]) ;;
    *) echo "已取消安装"; exit 0;;
  esac
  wget -N --no-check-certificate https://github.com/ginuerzh/gost/releases/download/v${latest_version}/gost-linux-${type}-${latest_version}.gz
  gzip -d gost-linux-${type}-${latest_version}.gz
  mv gost-linux-${type}-${latest_version} /usr/local/bin/gost
  chmod +x /usr/local/bin/gost
  cat > /etc/systemd/system/gost.service <<EOF
[Unit]
Description=gost proxy service
After=network.target

[Service]
Type=simple
User=root
Group=nogroup
LimitNOFILE=32768
ExecStart=/usr/local/bin/gost -L "socks5://${gost_username}:${gost_password}@:${gost_port}?udp=true&bind=true"
StandardOutput=null
StandardError=null
SyslogIdentifier=gost

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl start gost.service
  systemctl enable gost.service
  echo "SOCKS5 安装成功"
  echo "客户端连接信息: "
  echo "端口: ${gost_port}"
  echo "用户: ${gost_username}"
  echo "密码: ${gost_password}"
}
socks5-tls() {
  read -r -p "请输入 SOCKS5-TLS 监听端口 (留空默认 1080): " gost_port
gost_port=${gost_port:-1080}
  read -r -p "请输入 SOCKS5-TLS 用户名 (留空随机生成): " gost_username
  if [[ -z "$gost_username" ]]; then
    gost_username=$(openssl rand -hex 8)
  fi
  read -r -p "请输入 SOCKS5-TLS 密码 (留空随机生成): " gost_password
  if [[ -z "$gost_password" ]]; then
    gost_password=$(openssl rand -hex 16)
  fi
  read -r -p "请输入证书文件路径: " cer_path
  read -r -p "请输入私钥文件路径: " key_path
  cat <<EOF
请确认以下配置信息：
协议：SOCKS5-TLS
端口：${gost_port}
用户：${gost_username}
密码：${gost_password}
证书路径：${cer_path}
私钥路径：${key_path}
EOF
  read -r -p "确认无误？(Y/N)" confirm
  case "$confirm" in
    [yY]) ;;
    *) echo "已取消安装"; exit 0;;
  esac
  wget -N --no-check-certificate https://github.com/ginuerzh/gost/releases/download/v${latest_version}/gost-linux-${type}-${latest_version}.gz
  gzip -d gost-linux-${type}-${latest_version}.gz
  mv gost-linux-${type}-${latest_version} /usr/local/bin/gost
  chmod +x /usr/local/bin/gost
  cat > /etc/systemd/system/gost.service <<EOF
[Unit]
Description=gost proxy service
After=network.target

[Service]
Type=simple
User=root
Group=nogroup
LimitNOFILE=32768
ExecStart=/usr/local/bin/gost -L "socks5+tls://${gost_username}:${gost_password}@:${gost_port}?udp=true&bind=true&cert=${cer_path}&key=${key_path}"
StandardOutput=null
StandardError=null
SyslogIdentifier=gost

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl start gost.service
  systemctl enable gost.service
  echo "SOCKS5-TLS 安装成功"
  echo "客户端连接信息: "
  echo "端口: ${gost_port}"
  echo "用户: ${gost_username}"
  echo "密码: ${gost_password}"
}
http() {
  read -r -p "请输入 HTTP 监听端口 (留空默认 1080): " gost_port
  gost_port=${gost_port:-1080}
  read -r -p "请输入 HTTP 用户名 (留空随机生成): " gost_username
  if [[ -z "$gost_username" ]]; then
    gost_username=$(openssl rand -hex 8)
  fi
  read -r -p "请输入 HTTP 密码 (留空随机生成): " gost_password
  if [[ -z "$gost_password" ]]; then
    gost_password=$(openssl rand -hex 16)
  fi
  cat <<EOF
请确认以下配置信息：
协议：HTTP
端口：${gost_port}
用户：${gost_username}
密码：${gost_password}
EOF
  read -r -p "确认无误？(Y/N)" confirm
  case "$confirm" in
    [yY]) ;;
    *) echo "已取消安装"; exit 0;;
  esac
  wget -N --no-check-certificate https://github.com/ginuerzh/gost/releases/download/v${latest_version}/gost-linux-${type}-${latest_version}.gz
  gzip -d gost-linux-${type}-${latest_version}.gz
  mv gost-linux-${type}-${latest_version} /usr/local/bin/gost
  chmod +x /usr/local/bin/gost
  cat > /etc/systemd/system/gost.service <<EOF
[Unit]
Description=gost proxy service
After=network.target

[Service]
Type=simple
User=root
Group=nogroup
LimitNOFILE=32768
ExecStart=/usr/local/bin/gost -L "http://${gost_username}:${gost_password}@:${gost_port}"
StandardOutput=null
StandardError=null
SyslogIdentifier=gost

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl start gost.service
  systemctl enable gost.service
  echo "HTTP 安裝成功"
  echo "客户端连接信息: "
  echo "端口: ${gost_port}"
  echo "用戶: ${gost_username}"
  echo "密码: ${gost_password}"
}
https() {
  read -r -p "请输入 HTTPS 监听端口 (留空默认 1080): " gost_port
gost_port=${gost_port:-1080}
  read -r -p "请输入 HTTPS 用户名 (留空随机生成): " gost_username
  if [[ -z "$gost_username" ]]; then
    gost_username=$(openssl rand -hex 8)
  fi
  read -r -p "请输入 HTTPS 密码 (留空随机生成): " gost_password
  if [[ -z "$gost_password" ]]; then
    gost_password=$(openssl rand -hex 16)
  fi
  read -r -p "请输入证书文件路径: " cer_path
  read -r -p "请输入私钥文件路径: " key_path
  cat <<EOF
请确认以下配置信息：
协议：HTTPS
端口：${gost_port}
用户：${gost_username}
密码：${gost_password}
证书路径：${cer_path}
私钥路径：${key_path}
EOF
  read -r -p "确认无误？(Y/N)" confirm
  case "$confirm" in
    [yY]) ;;
    *) echo "已取消安装"; exit 0;;
  esac
  wget -N --no-check-certificate https://github.com/ginuerzh/gost/releases/download/v${latest_version}/gost-linux-${type}-${latest_version}.gz
  gzip -d gost-linux-${type}-${latest_version}.gz
  mv gost-linux-${type}-${latest_version} /usr/local/bin/gost
  chmod +x /usr/local/bin/gost
  cat > /etc/systemd/system/gost.service <<EOF
[Unit]
Description=gost proxy service
After=network.target

[Service]
Type=simple
User=root
Group=nogroup
LimitNOFILE=32768
ExecStart=/usr/local/bin/gost -L "https://${gost_username}:${gost_password}@:${gost_port}?cert=${cer_path}&key=${key_path}"
StandardOutput=null
StandardError=null
SyslogIdentifier=gost

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl start gost.service
  systemctl enable gost.service
  echo "HTTPS 安装成功"
  echo "客户端连接信息: "
  echo "端口: ${gost_port}"
  echo "用户: ${gost_username}"
  echo "密码: ${gost_password}"
}
if [[ $1 == "uninstall" ]]; then
  uninstall
  exit 0
fi
if [[ $1 == "update" ]]; then
  update
  exit 0
fi
if [[ $1 == "socks5-tls" ]]; then
  socks5
  exit 0
fi
if [[ $1 == "socks5" ]]; then
  socks5
  exit 0
fi
if [[ $1 == "http" ]]; then
  http
  exit 0
fi
if [[ $1 == "https" ]]; then
  https
  exit 0
fi
