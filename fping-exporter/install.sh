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
latest_version=$(curl -m 10 -sL "https://api.github.com/repos/midori01/fping-exporter/releases/latest" | awk -F'"' '/tag_name/{gsub(/v/, "", $4); print $4}')
install() {
command -v fping >/dev/null 2>&1 || { if command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then yum install -y fping || dnf install -y fping; else apt update -qq && apt install -y fping; fi; }
wget https://github.com/midori01/fping-exporter/releases/download/${latest_version}/fping-exporter-linux-${type}
mv fping-exporter-linux-${type} /etc/fping-exporter
chmod +x /etc/fping-exporter
cat > /etc/systemd/system/fping-exporter.service <<EOF
[Unit]
Description=This is Prometheus Fping-Exporter

[Service]
Type=simple
ExecStart=/etc/fping-exporter -p 15 -c 15
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable fping-exporter.service --now
}
uninstall() {
systemctl disable fping-exporter.service --now
rm -f /etc/systemd/system/fping-exporter.service
rm -r /etc/fping-exporter
echo "fping-exporter 卸载成功"
}
update() {
rm -f /etc/fping-exporter
wget https://github.com/midori01/fping-exporter/releases/download/${latest_version}/fping-exporter-linux-${type}
mv fping-exporter-linux-${type} /etc/fping-exporter
chmod +x /etc/fping-exporter
systemctl restart fping-exporter.service
echo "fping-exporter 更新成功"
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
fping_exporter_port=`ss -ntlp | grep -o 9605`
if [ $fping_exporter_port == "9605" ];then
    ${COLOR}fping-exporter 安装成功${END}
else
    ${COLOR1}fping-exporter 安装失败${END}
fi