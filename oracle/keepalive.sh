#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi
if ! command -v docker &> /dev/null; then
  echo "docker 未安装，请安装后再运行脚本"
  exit 1
fi
remove() {
if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi
  docker stop keeporaclealive
  crontab -l | grep -v "keeporaclealive" | crontab -
  echo "Keep Oracle Alive 任务已清除"
}
if [[ $1 == "remove" ]]; then
  remove
  exit 0
fi
(crontab -l ; echo '0 8 * * * docker run -d --name keeporaclealive --rm alpine sh -c "while true; do for i in {1..100000}; do j=$((i*i)); done; done"'; echo '0 11 * * * docker stop keeporaclealive') | crontab -
timedatectl set-timezone Asia/Tokyo
service cron restart
echo "Keep Oracle Alive 任务已添加"
