#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi

echo net.core.default_qdisc=fq >> /etc/sysctl.conf
echo net.ipv4.tcp_congestion_control=bbr >> /etc/sysctl.conf
echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf
echo 3 > /proc/sys/net/ipv4/tcp_fastopen
echo net.ipv4.tcp_fastopen=3 >> /etc/sysctl.conf

sysctl -p

echo "BBR & TCP Fast Open & IPv4 Forward 已开启"
