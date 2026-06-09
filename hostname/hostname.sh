#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi
current_hostname=$(hostname)
echo "当前主机名为：${current_hostname}"
read -p "请输入新主机名：" new_hostname
read -p "您输入的新主机名为：${new_hostname}，是否确认修改？[Y/n]" confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "已取消修改主机名"
    exit 1
fi
echo "${new_hostname}" > /etc/hostname
hostnamectl set-hostname "${new_hostname}"
echo "修改后的主机名为：$(hostname)"
