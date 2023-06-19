#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi
if ! command -v wget &> /dev/null; then
  echo "wget 未安装，请安装后再运行脚本"
  exit 1
fi
if ! command -v unzip &> /dev/null; then
  echo "unzip 未安装，请安装后再运行脚本"
  exit 1
fi
wget https://cdn.ipip.net/17mon/besttrace4linux.zip
unzip besttrace4linux.zip -d best
chmod +x best/besttrace*
arch=$(uname -m)
if [[ "$arch" == "x86_64" ]]; then
  mv best/besttrace /usr/bin/besttrace
elif [[ "$arch" == "aarch64" ]]; then
  mv best/besttracearm /usr/bin/besttrace
else
  echo "$arch 架构不支持"
  exit 1
fi
rm -r best besttrace4linux.zip
echo "BestTrace 已安装"
