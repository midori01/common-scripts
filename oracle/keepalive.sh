#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi

if ! command -v docker &> /dev/null; then
  echo "docker 未安装，请安装后再运行脚本"
  exit 1
fi

crontab -l > conf
echo -e "0 8 * * * docker run -d --name keeporaclealive --rm alpine sh -c \"while true; do for i in {1..100000}; do j=$((i*i)); done; done\" >> /tmp/tmp.txt\n0 11 * * * docker stop keeporaclealive >> /tmp/tmp.txt" >> conf
crontab conf
rm -f conf
timedatectl set-timezone Asia/Tokyo
service cron restart
