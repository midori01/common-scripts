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

uninstall() {
  killall gost
  rm -f /usr/local/bin/gost
  echo "SOCKS5 已卸载"
}

if [[ $1 == "uninstall" ]]; then
  uninstall
  exit 0
fi

if [[ "$(uname -m)" == "x86_64" ]]; then
  type="amd64"
elif [[ "$(uname -m)" == "aarch64" ]]; then
  type="armv8"
else
  echo "$(uname -m) 架构不支持"
  exit 1
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

nohup /usr/local/bin/gost -L "socks5://${socks5_username}:${socks5_password}@:${socks5_port}?udp=true&bind=true" > /dev/null 2>&1 &

echo "SOCKS5 安装成功"
echo "客户端连接信息: "
echo "端口: ${socks5_port}"
echo "用户: ${socks5_username}"
echo "密码: ${socks5_password}"
