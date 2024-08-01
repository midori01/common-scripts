#!/bin/bash

apt update
apt install ocserv -y
cat > /etc/ocserv/ocserv.conf <<'EOF'
# openconnect server user
run-as-user = ocserv
run-as-group = ocserv

# require file while server run
socket-file = /run/ocserv-socket
chroot-dir = /var/lib/ocserv

# isolate sub proccess control
isolate-workers = true

# net interface for server
device = op

# mtu size for server
mtu = 1480

# log level
log-level = 1

# auth method
auth = "plain[/etc/ocserv/ocpasswd]"
 
# maximum users allowed connect
max-clients = 10
 
# maximum client allowed connect for per user
max-same-clients = 5
 
# server listen address (default is all)
# listen-host = 127.0.0.1
# udp-listen-host = 0.0.0.0
 
# server listen ports (default is 443, but can modified)
tcp-port = 8443
udp-port = 8443
 
# mtu auto discovery for per tunnel
try-mtu-discovery = true
 
# user certificate type
# cert-user-oid = 2.5.4.3
 
# certificate and private key for server
server-cert = /etc/ocserv/server.pem
server-key = /etc/ocserv/server.key

# dns while clients connected use
dns = 1.1.1.1
dns = 1.0.0.1
tunnel-all-dns = true

# route option (set it to default as a gateway)
#route = 192.168.1.0/255.255.255.0
route = default
 
# enable cisco anyconnect compatible
cisco-client-compat = true

# keep alive interval
keepalive = 32400
dpd = 60
mobile-dpd = 120

# other option
output-buffer = 0
rate-limit-ms = 0

# access control
restrict-user-to-routes = false
restrict-user-to-ports = ""

# disconnected idle time
# idle-timeout = 1200
# mobile-idle-timeout = 1800

# dtls protocol control
dtls-legacy = true
switch-to-tcp-timeout = 30
tls-priorities = "NORMAL:%SERVER_PRECEDENCE:%COMPAT:-VERS-SSL3.0:-VERS-TLS1.0:-VERS-TLS1.1:-VERS-TLS1.2"

# compression control
compression = true
no-compress-limit = 0

# speed limit by per client
rx-data-per-sec = 0
tx-data-per-sec = 0

# client auth control
auth-timeout = 240
min-reauth-time = 300
max-ban-score = 80
ban-reset-time = 1200

# client status control
cookie-timeout = 600
rekey-time = 172800
deny-roaming = false
use-occtl = true

# internal network settings
ipv4-network = 10.11.11.0/24
ipv6-network = fd11::/80
ipv6-subnet-prefix = 128
client-bypass-protocol = false
predictable-ips = true
ping-leases = true
net-priority = 3
EOF
cp /WebDAV/cert/server.* /etc/ocserv/
systemctl restart ocserv.service
iptables -I FORWARD -s 10.11.11.0/24 -j ACCEPT
iptables -I FORWARD -d 10.11.11.0/24 -j ACCEPT
ip6tables -I FORWARD -s fd11::/80 -j ACCEPT
ip6tables -I FORWARD -d fd11::/80 -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.11.11.0/24 ! -o op+ -j MASQUERADE
ip6tables -t nat -A POSTROUTING -s fd11::/80 ! -o op+ -j MASQUERADE
