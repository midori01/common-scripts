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
latest_version=$(curl -m 10 -sL "https://api.github.com/repos/prometheus/blackbox_exporter/releases/latest" | awk -F'"' '/tag_name/{gsub(/v/, "", $4); print $4}')
install() {
wget https://github.com/prometheus/blackbox_exporter/releases/download/v${latest_version}/blackbox_exporter-${latest_version}.linux-${type}.tar.gz
tar zxvf blackbox_exporter-${latest_version}.linux-${type}.tar.gz
mkdir /etc/blackbox_exporter
mv blackbox_exporter-${latest_version}.linux-${type}/blackbox_exporter /etc/blackbox_exporter/blackbox_exporter
mv blackbox_exporter-${latest_version}.linux-${type}/blackbox.yml /etc/blackbox_exporter/blackbox.yml
chmod +x /etc/blackbox_exporter/blackbox_exporter
rm -r blackbox_exporter-${latest_version}.linux-${type}
rm -f blackbox_exporter-${latest_version}.linux-${type}.tar.gz
cat > /etc/systemd/system/blackbox-exporter.service <<EOF
[Unit]
Description=This is prometheus blackbox exporter

[Service]
Type=simple
ExecStart=/etc/blackbox_exporter/blackbox_exporter
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl start blackbox-exporter.service
systemctl enable blackbox-exporter.service
}
uninstall() {
systemctl stop blackbox-exporter.service
systemctl disable blackbox-exporter.service
rm -f /etc/systemd/system/blackbox-exporter.service
rm -r /etc/blackbox_exporter
echo "blackbox-exporter 卸载成功"
}
update() {
rm -f /etc/blackbox_exporter/blackbox_exporter
wget https://github.com/prometheus/blackbox_exporter/releases/download/v${latest_version}/blackbox_exporter-${latest_version}.linux-${type}.tar.gz
tar zxvf blackbox_exporter-${latest_version}.linux-${type}.tar.gz
mv blackbox_exporter-${latest_version}.linux-${type}/blackbox_exporter /etc/blackbox_exporter/blackbox_exporter
chmod +x /etc/blackbox_exporter/blackbox_exporter
rm -r blackbox_exporter-${latest_version}.linux-${type}
rm -f blackbox_exporter-${latest_version}.linux-${type}.tar.gz
systemctl restart blackbox-exporter.service
echo "blackbox-exporter 更新成功"
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
blackbox_exporter_port=`ss -ntlp | grep -o 9115`
if [ $blackbox_exporter_port == "9115" ];then
    ${COLOR}blackbox-exporter 安装成功${END}
else
    ${COLOR1}blackbox-exporter 安装失败${END}
fi
