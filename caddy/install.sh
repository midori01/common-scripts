#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi
uninstall() {
  apt purge -y caddy
  apt autoremove -y
  rm -f /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  rm -f /etc/apt/sources.list.d/caddy-stable.list
  echo “Caddy 已卸载”
}
if [[ $1 == "uninstall" ]]; then
  uninstall
  exit 0
fi
apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
apt update
apt install -y caddy
echo "Caddy 安装成功"
