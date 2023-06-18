#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi

sshkey() {
  echo "请粘贴公钥内容："
  read ssh_public_key
  rm -r /root/.ssh
  mkdir /root/.ssh
  echo "$ssh_public_key" > /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
  chmod 700 /root/.ssh
  service sshd restart
  echo "SSH 公钥已添加"
}

enablepwd() {
  sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
  service sshd restart
  echo "密码登录已开启"
}

disablepwd() {
  sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config
  service sshd restart
  echo "密码登录已关闭"
}

rootlogin() {
  sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
  service sshd restart
  echo "root 登录已开启"
}

if [[ $1 == "sshkey" ]]; then
  sshkey
  exit 0
fi

if [[ $1 == "enablepwd" ]]; then
  enablepwd
  exit 0
fi

if [[ $1 == "disablepwd" ]]; then
  disablepwd
  exit 0
fi

if [[ $1 == "rootlogin" ]]; then
  rootlogin
  exit 0
fi
