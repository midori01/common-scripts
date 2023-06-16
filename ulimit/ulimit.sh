#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi

echo " * soft nofile 102400" >> /etc/security/limits.conf
echo " * hard nofile 102400" >> /etc/security/limits.conf
