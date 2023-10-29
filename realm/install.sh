#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi
if ! command -v wget &> /dev/null; then
  echo "wget 未安装，请安装后再运行脚本"
  exit 1
fi
if ! command -v jq &> /dev/null; then
  echo "jq 未安装，请安装后再运行脚本"
  exit 1
fi
latest_release=$(curl -s https://api.github.com/repos/zhboner/realm/releases/latest)
if [[ "$(echo "$latest_release" | jq -r '.message')" == "Not Found" ]]; then
  echo "获取最新版本失败"
  exit 1
fi
realm_version=$(echo "$latest_release" | jq -r '.tag_name')
arch=$(uname -m)
if [[ "$arch" == "x86_64" ]]; then
  realm_package="realm-x86_64-unknown-linux-gnu.tar.gz"
elif [[ "$arch" == "aarch64" ]]; then
  realm_package="realm-aarch64-unknown-linux-gnu.tar.gz"
else
  echo "$arch 架构不支持"
  exit 1
fi
uninstall() {
  systemctl stop realm.service
  systemctl disable realm.service
  rm -f /etc/systemd/system/realm.service
  rm -f /root/realm.conf
  rm -f /usr/local/bin/realm
  echo "RealM 已卸载"
}
update() {
  rm /usr/local/bin/realm
  wget https://github.com/zhboner/realm/releases/download/"$realm_version"/"$realm_package"
  tar -zxvf "$realm_package"
  rm -f "$realm_package"
  mv realm /usr/local/bin/realm
  chmod +x /usr/local/bin/realm
  systemctl restart realm.service
  echo "RealM 已更新"
}
if [[ $1 == "uninstall" ]]; then
  uninstall
  exit 0
fi
if [[ $1 == "update" ]]; then
  update
  exit 0
fi
read -p "请输入监听端口（支持多端口，以逗号分隔）：" listening_ports
read -p "请输入目标地址（支持多目标，以逗号分隔）：" remote_addresses
read -p "请输入目标端口（支持多端口，以逗号分隔，留空则与监听端口相同）：" remote_ports
if [[ -z "$remote_ports" ]]; then
  remote_ports="$listening_ports"
fi
listening_ports=$(echo "$listening_ports" | sed 's/,/","/g')
remote_addresses=$(echo "$remote_addresses" | sed 's/,/","/g')
remote_ports=$(echo "$remote_ports" | sed 's/,/","/g')
wget https://github.com/zhboner/realm/releases/download/"$realm_version"/"$realm_package"
tar -zxvf "$realm_package"
rm -f "$realm_package"
mv realm /usr/local/bin/realm
chmod +x /usr/local/bin/realm
cat > /root/realm.json <<EOF
{
    "listening_addresses": ["[::]"],
    "listening_ports": ["$listening_ports"],
    "remote_addresses": ["$remote_addresses"],
    "remote_ports": ["$remote_ports"]
}
EOF
cat > /etc/systemd/system/realm.service <<EOF
[Unit]
Description=realm
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
Type=simple
User=root
Restart=on-failure
RestartSec=5s
DynamicUser=true
WorkingDirectory=/usr/local/bin
ExecStart=/usr/local/bin/realm -u -c /root/realm.json

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable realm.service
systemctl start realm.service
echo "RealM 已安装"
