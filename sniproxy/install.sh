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
fi
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
user root
pidfile /var/tmp/sniproxy.pid

error_log {
    syslog daemon
    priority notice
}

resolver {
    nameserver 1.1.1.1
    nameserver 1.0.0.1
    mode ipv4_first
}

listener 80 {
    proto http
}

listener 443 {
    proto tls
}

table {
    .* *
}
EOF
systemctl daemon-reload
systemctl enable sniproxy.service --now
echo "done!"
