#!/bin/bash

uninstall() {
  systemctl disable sniproxy.service --now
  rm -f /etc/systemd/system/sniproxy.service
  apt purge sniproxy -y
  echo "done! "
}
if [[ $1 == "uninstall" ]]; then
  uninstall
  exit 0
apt update && apt install sniproxy -y
cat > /etc/systemd/system/sniproxy.service <<EOF
[Unit]
Description=Sniproxy
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
LimitCORE=infinity
LimitNOFILE=512000
LimitNPROC=512000
Type=forking
User=root
Restart=always
RestartSec=5s
ExecStart=/usr/sbin/sniproxy -c /etc/sniproxy.conf

[Install]
WantedBy=multi-user.target
EOF
cat > /etc/sniproxy.conf <<EOF
listener 80 {
    proto http
}

listener 443 {
    proto tls
}

table {
    example1.com 127.0.0.1:8080
    example2.com 127.0.0.1:8443
}
EOF
systemctl daemon-reload
systemctl enable sniproxy.service --now
echo "done!"
