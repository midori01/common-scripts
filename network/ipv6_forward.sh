#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi

echo net.ipv6.conf.all.forwarding=1 >> /etc/sysctl.conf

sysctl -p

echo "IPv6 Forward 已开启"
