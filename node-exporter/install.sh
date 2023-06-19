#!/bin/bash
set -e
COLOR="echo -e \\E[1;32m"
COLOR1="echo -e \\E[1;31m"
END="\\E[0m"
install_dir="/apps"
if [[ "$(uname -m)" == "x86_64" ]]; then
  download_url="https://github.com/prometheus/node_exporter/releases/download/v1.5.0/node_exporter-1.5.0.linux-amd64.tar.gz"
  package_name="node_exporter-1.5.0.linux-amd64.tar.gz"
  node_exporter_name="node_exporter-1.5.0.linux-amd64"
elif [[ "$(uname -m)" == "aarch64" ]]; then
  download_url="https://github.com/prometheus/node_exporter/releases/download/v1.5.0/node_exporter-1.5.0.linux-arm64.tar.gz"
  package_name="node_exporter-1.5.0.linux-arm64.tar.gz"
  node_exporter_name="node_exporter-1.5.0.linux-arm64"
else
  echo "$(uname -m) 架构不支持"
  exit 1
fi
if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi
node_exporter_install() {
[ -f ${install_dir} ] || mkdir -p $install_dir
cd $install_dir
wget ${download_url}
tar xf ${package_name}
ln -sv ${node_exporter_name} node_exporter
rm ${package_name}
cat > /usr/lib/systemd/system/node-exporter.service <<EOF
[Unit]
Description=This is prometheus node exporter

[Service]
Type=simple
ExecStart=/apps/node_exporter/node_exporter
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
rm -f /usr/lib/systemd/system/node-exporter.service
rm -r ${install_dir}
echo "node-exporter卸载成功"
}
if [[ $1 == "uninstall" ]]; then
  uninstall
  exit 0
fi
node_exporter_install
node_exporter_port=`ss -ntlp | grep -o 9100`
if [ $node_exporter_port == "9100" ];then
    ${COLOR}node-exporter安装成功!${END}
else
    ${COLOR1}node-exporter安装失败!${END}
fi
