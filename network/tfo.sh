#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi

echo 3 > /proc/sys/net/ipv4/tcp_fastopen
echo net.ipv4.tcp_fastopen=3 >> /etc/sysctl.conf

sysctl -p

echo "TCP Fast Open 已开启"
