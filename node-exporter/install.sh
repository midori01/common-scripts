#!/bin/bash
set -e
COLOR="echo -e \\E[1;32m"
COLOR1="echo -e \\E[1;31m"
END="\\E[0m"
if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi
if [[ "$(uname -m)" == "x86_64" ]]; then
  type=amd64
elif [[ "$(uname -m)" == "aarch64" ]]; then
  type=arm64
else
  echo "$(uname -m) 架构不支持"
  exit 1
fi
latest_version=$(curl -m 10 -sL "https://api.github.com/repos/prometheus/node_exporter/releases/latest" | awk -F'"' '/tag_name/{gsub(/v/, "", $4); print $4}')
install() {
if ss -tuln | grep -q ":9100"; then
  echo "端口 9100 已被占用"
  exit 1
fi
wget https://github.com/prometheus/node_exporter/releases/download/v${latest_version}/node_exporter-${latest_version}.linux-${type}.tar.gz
tar zxvf node_exporter-${latest_version}.linux-${type}.tar.gz
mv node_exporter-${latest_version}.linux-${type}/node_exporter /usr/local/bin/node_exporter
chmod +x /usr/local/bin/node_exporter
rm -rf node_exporter-${latest_version}.linux-${type}
rm -rf node_exporter-${latest_version}.linux-${type}.tar.gz
cat > /etc/systemd/system/node-exporter.service <<EOF
[Unit]
Description=This is prometheus node exporter

[Service]
Type=simple
ExecStart=/usr/local/bin/node_exporter --web.listen-address=":9100"
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl start node-exporter.service
systemctl enable node-exporter.service
}
uninstall() {
systemctl stop node-exporter.service
systemctl disable node-exporter.service
rm -rf /etc/systemd/system/node-exporter.service
rm -rf /usr/local/bin/node_exporter
rm -rf /etc/node_exporter
echo "node-exporter 卸载成功"
}
update() {
rm -rf /usr/local/bin/node_exporter
rm -rf /etc/node_exporter/node_exporter
wget https://github.com/prometheus/node_exporter/releases/download/v${latest_version}/node_exporter-${latest_version}.linux-${type}.tar.gz
tar zxvf node_exporter-${latest_version}.linux-${type}.tar.gz
mv node_exporter-${latest_version}.linux-${type}/node_exporter /usr/local/bin/node_exporter
chmod +x /usr/local/bin/node_exporter
rm -rf node_exporter-${latest_version}.linux-${type}
rm -rf node_exporter-${latest_version}.linux-${type}.tar.gz
sed -i 's/ExecStart\=\/etc\/node_exporter\/node_exporter/ExecStart\=\/usr\/local\/bin\/node_exporter/g' /etc/systemd/system/node-exporter.service
systemctl daemon-reload
systemctl restart node-exporter.service
echo "node-exporter 更新成功"
}
if [[ $1 == "uninstall" ]]; then
  uninstall
  exit 0
fi
if [[ $1 == "update" ]]; then
  update
  exit 0
fi
install
node_exporter_port=`ss -ntlp | grep -o 9100`
if [ $node_exporter_port == "9100" ];then
    ${COLOR}node-exporter 安装成功${END}
else
    ${COLOR1}node-exporter 安装失败${END}
fi
