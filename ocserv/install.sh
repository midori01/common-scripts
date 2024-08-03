#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi
uninstall() {
  systemctl disable ocserv.service --now
  apt purge ocserv -y
  rm -r /etc/ocserv
  iptables -D FORWARD -s 10.11.11.0/24 -j ACCEPT
  iptables -D FORWARD -d 10.11.11.0/24 -j ACCEPT
  ip6tables -D FORWARD -s fd11::/80 -j ACCEPT
  ip6tables -D FORWARD -d fd11::/80 -j ACCEPT
  iptables -t nat -D POSTROUTING -s 10.11.11.0/24 ! -o op+ -j MASQUERADE
  ip6tables -t nat -D POSTROUTING -s fd11::/80 ! -o op+ -j MASQUERADE
  echo "ocserv 已卸载"
}
if [[ $1 == "uninstall" ]]; then
  uninstall
  exit 0
fi
read -r -p "请输入监听端口 (留空默认 443): " listen_port
listen_port=${listen_port:-443}
read -r -p "请输入证书路径 (留空使用 /etc/ocserv/cert.pem): " cert_path
cert_path=${cert_path:-/etc/ocserv/cert.pem}
read -r -p "请输入私钥路径 (留空使用 /etc/ocserv/key.pem): " key_path
key_path=${key_path:-/etc/ocserv/key.pem}
apt update && apt install ocserv -y
cat > /etc/ocserv/ocserv.conf <<EOF
log-level = 1
run-as-user = ocserv
run-as-group = ocserv
socket-file = /run/ocserv-socket
chroot-dir = /var/lib/ocserv
isolate-workers = true
device = op
mtu = 1480
try-mtu-discovery = true
auth = "plain[/etc/ocserv/ocpasswd]"
# auth = "certificate
max-clients = 10
max-same-clients = 5
# listen-host = 127.0.0.1
# udp-listen-host = 0.0.0.0
tcp-port = ${listen_port}
udp-port = ${listen_port}
server-cert = ${cert_path}
server-key = ${key_path}
# ca-cert = /etc/ocserv/ca.pem
# cert-user-oid = 2.5.4.3
# default-domain = 
dns = 1.1.1.1
dns = 1.0.0.1
tunnel-all-dns = true
route = default
cisco-client-compat = true
keepalive = 32400
dpd = 60
mobile-dpd = 120
output-buffer = 0
rate-limit-ms = 0
restrict-user-to-routes = false
restrict-user-to-ports = ""
dtls-legacy = true
switch-to-tcp-timeout = 30
tls-priorities = "NORMAL:%SERVER_PRECEDENCE:%COMPAT:-VERS-SSL3.0:-VERS-TLS1.0:-VERS-TLS1.1:-VERS-TLS1.2"
compression = true
no-compress-limit = 0
rx-data-per-sec = 0
tx-data-per-sec = 0
auth-timeout = 240
min-reauth-time = 300
max-ban-score = 80
ban-reset-time = 1200
cookie-timeout = 600
rekey-time = 172800
deny-roaming = false
use-occtl = true
ipv4-network = 10.11.11.0/24
ipv6-network = fd11::/80
ipv6-subnet-prefix = 128
client-bypass-protocol = false
predictable-ips = true
ping-leases = true
net-priority = 3
EOF
systemctl restart ocserv.service
systemctl enable ocserv.service
iptables -I FORWARD -s 10.11.11.0/24 -j ACCEPT
iptables -I FORWARD -d 10.11.11.0/24 -j ACCEPT
ip6tables -I FORWARD -s fd11::/80 -j ACCEPT
ip6tables -I FORWARD -d fd11::/80 -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.11.11.0/24 ! -o op+ -j MASQUERADE
ip6tables -t nat -A POSTROUTING -s fd11::/80 ! -o op+ -j MASQUERADE
echo "ocserv 安装成功"
echo "添加用户: ocpasswd -c /etc/ocserv/ocpasswd example-username"
echo "重启服务: systemctl restart ocserv.service"
echo "配置路径: /etc/ocserv/ocserv.conf"
