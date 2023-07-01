#!/bin/bash

if [[ "$(uname -m)" == "x86_64" ]]; then
  os_type="amd64"
elif [[ "$(uname -m)" == "aarch64" ]]; then
  os_type="arm64"
else
  exit 1
fi
latest_version=$(curl -m 10 -sL "https://api.github.com/repos/shadowsocks/v2ray-plugin/releases/latest" | awk -F'"' '/tag_name/{print $4}')
wget "https://github.com/shadowsocks/v2ray-plugin/releases/download/${latest_version}/v2ray-plugin-linux-${os_type}-${latest_version}.tar.gz"
tar zxvf v2ray-plugin-linux-${os_type}-${latest_version}.tar.gz
rm -f v2ray-plugin-linux-${os_type}-${latest_version}.tar.gz
mv ./v2ray-plugin_linux_${os_type} /usr/local/bin/v2ray-plugin
chmod +x /usr/local/bin/v2ray-plugin
v2ray-plugin -version
