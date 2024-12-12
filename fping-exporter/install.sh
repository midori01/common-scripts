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
latest_version=$(curl -m 10 -sL "https://api.github.com/repos/midori01/fping-exporter/releases/latest" | awk -F'"' '/tag_name/{print $4}')
install() {
if ss -tuln | grep -q ":9605"; then
  echo "端口 9605 已被占用"
  exit 1
fi
command -v fping >/dev/null 2>&1 || { if command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then yum install -y fping || dnf install -y fping; else apt update -qq && apt install -y fping; fi; }
wget https://github.com/midori01/fping-exporter/releases/download/${latest_version}/fping-exporter-linux-${type}
mv fping-exporter-linux-${type} /usr/local/bin/fping-exporter
chmod +x /usr/local/bin/fping-exporter
cat > /etc/systemd/system/fping-exporter.service <<EOF
[Unit]
Description=This is Prometheus Fping-Exporter

[Service]
Type=simple
ExecStart=/usr/local/bin/fping-exporter -p 15 -c 15 -l :9605
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
apt purge fping -y
systemctl disable fping-exporter.service --now
rm -rf /etc/systemd/system/fping-exporter.service
rm -rf /etc/fping-exporter
rm -rf /usr/local/bin/fping-exporter
echo "fping-exporter 卸载成功"
}
update() {
rm -rf /usr/local/bin/fping-exporter
rm -rf /etc/fping-exporter
wget https://github.com/midori01/fping-exporter/releases/download/${latest_version}/fping-exporter-linux-${type}
mv fping-exporter-linux-${type} /usr/local/bin/fping-exporter
chmod +x /usr/local/bin/fping-exporter
sed -i 's/ExecStart\=\/etc\/fping-exporter/ExecStart\=\/usr\/local\/bin\/fping-exporter/g' /etc/systemd/system/fping-exporter.service
systemctl daemon-reload
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
fping_exporter_status=$(systemctl is-active fping-exporter)
if [[ "$fping_exporter_status" == "active" ]]; then
    ${COLOR}fping-exporter 安装成功${END}
else
    sleep 2
    fping_exporter_port=$(ss -ntlp | grep -o '9605' | head -n 1)
    if [[ "$fping_exporter_port" == "9605" ]]; then
        ${COLOR}fping-exporter 安装成功${END}
    else
        ${COLOR1}fping-exporter 安装失败${END}
    fi
fi