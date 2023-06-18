#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi

echo "请粘贴公钥内容："
read ssh_public_key

rm -r /root/.ssh
mkdir /root/.ssh
echo "$ssh_public_key" > /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
chmod 700 /root/.ssh

echo "SSH 公钥已添加"
