#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi
apt update
apt install -y python3 python3-pip
pip3 install tcping
echo "tcping 已安装"
