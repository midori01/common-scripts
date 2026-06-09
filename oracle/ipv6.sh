#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi
if ! command -v ifup &> /dev/null; then
  echo "ifupdown 未安装，请安装后再运行脚本"
  exit 1
fi
if ! command -v curl &> /dev/null; then
  echo "curl 未安装，请安装后再运行脚本"
  exit 1
fi
netdevice=$(ip route get 1.1.1.1 | awk -F"dev " '{print $2}' | awk '{print $1; exit}')
echo "iface ${netdevice} inet6 dhcp" >> /etc/network/interfaces
ifdown ${netdevice} && ifup ${netdevice}
sleep 15
echo "IPv6 地址已添加"
echo "$(curl -s ip.sb -6)"
