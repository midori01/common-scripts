#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi
if ! command -v iptables &> /dev/null; then
  echo "iptables 未安装，请安装后再运行脚本"
  exit 1
fi
uninstall() {
  wg-quick down wg0
  systemctl disable wg-quick@wg0
  rm /etc/wireguard/wg0.conf
  apt purge -y wireguard wireguard-tools
  echo "WireGuard 已卸载"
}
peer() {
  read -r -p "请输入备注: " note
  read -r -p "请输入 Peer 公钥: " peer_public_key
  read -r -p "请输入 Self IP: " peer_self_ipv4
  last_octet=$(echo "${peer_self_ipv4}" | awk -F. '{print $4}')
  peer_self_ipv6="fd10::${last_octet}"
  echo "" >> /etc/wireguard/wg0.conf
  echo "# ${note}" >> /etc/wireguard/wg0.conf
  echo "[Peer]" >> /etc/wireguard/wg0.conf
  echo "PublicKey = ${peer_public_key}" >> /etc/wireguard/wg0.conf
  echo "AllowedIPs = ${peer_self_ipv4}/32, ${peer_self_ipv6}/128" >> /etc/wireguard/wg0.conf
  wg syncconf wg0 <(wg-quick strip wg0)
  wg show wg0
}
reserved() {
  read -p "请输入 access_token (留空将从 wgcf-account.toml 文件中获取): " access_token_input
  if [ -z "$access_token_input" ]; then
    if [ -f "/etc/wireguard/wgcf-account.toml" ]; then
      access_token=$(grep -Po "(?<=access_token = ')[^']+" /etc/wireguard/wgcf-account.toml)
    else
      echo "/etc/wireguard/wgcf-account.toml 文件不存在"
      exit 1
    fi
  else
    access_token="$access_token_input"
  fi
  if [ -n "$access_token" ]; then
    read -p "请输入 device_id (留空将从 wgcf-account.toml 文件中获取): " device_id_input
    if [ -z "$device_id_input" ]; then
      if [ -f "/etc/wireguard/wgcf-account.toml" ]; then
        device_id=$(grep -Po "(?<=device_id = ')[^']+" /etc/wireguard/wgcf-account.toml)
      else
        echo "/etc/wireguard/wgcf-account.toml 文件不存在"
        exit 1
      fi
    else
      device_id="$device_id_input"
    fi
  fi
  response=$(curl --request GET "https://api.cloudflareclient.com/v0a2158/reg/${device_id}" \
    --silent \
    --location \
    --header 'User-Agent: okhttp/3.12.1' \
    --header 'CF-Client-Version: a-6.10-2158' \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer ${access_token}")
  client_id=$(echo "$response" | grep -Po '(?<=client_id":")[^"]+')
  decoded_client_id=$(echo "$client_id" | base64 -d | xxd -p | fold -w2 | while read HEX; do printf '%d ' "0x${HEX}"; done | awk '{print "["$1", "$2", "$3"]"}')
  echo "WARP Reserved: ${decoded_client_id}"
}
clientid() {
  read -r -p "请输入 WARP client_id: " client_id
  decoded_client_id=$(echo "$client_id" | base64 -d | xxd -p | fold -w2 | while read HEX; do printf '%d ' "0x${HEX}"; done | awk '{print "["$1", "$2", "$3"]"}')
  echo "WARP Reserved: ${decoded_client_id}"
}
if [[ $1 == "uninstall" ]]; then
  uninstall
  exit 0
fi
if [[ $1 == "peer" ]]; then
  peer
  exit 0
fi
if [[ $1 == "reserved" ]]; then
  reserved
  exit 0
fi
if [[ $1 == "clientid" ]]; then
  clientid
  exit 0
fi
read -r -p "请输入 WireGuard 端口 (留空默认 8964): " wg_port
wg_port=${wg_port:-8964}
echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf
sysctl -p
apt install -y wireguard wireguard-tools
netdevice=$(ip route get 1.1.1.1 | awk -F"dev " '{print $2}' | awk '{print $1; exit}')
i_privatekey=$(wg genkey | tee i_private.key)
i_publickey=$(cat i_private.key | wg pubkey)
p_privatekey=$(wg genkey | tee p_private.key)
p_publickey=$(cat p_private.key | wg pubkey)
endpoint=$(curl -s ip.sb -4)
section_name=$(cat /dev/urandom | tr -dc 'A-Z0-9' | fold -w 8 | head -n 1)
cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
Address = 10.89.64.1/32, fd10::1/128
PrivateKey = ${i_privatekey}
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o ${netdevice} -j MASQUERADE; ip6tables -A FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -A POSTROUTING -o ${netdevice} -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o ${netdevice} -j MASQUERADE; ip6tables -D FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -D POSTROUTING -o ${netdevice} -j MASQUERADE
ListenPort = ${wg_port}
MTU = 1280

[Peer]
PublicKey = ${p_publickey}
AllowedIPs = 10.89.64.2/32, fd10::2/128
EOF
rm -f i_private.key p_private.key
wg-quick up wg0
systemctl enable wg-quick@wg0
cat > /etc/wireguard/wg_surge.conf <<EOF
[Proxy]
WG-Proxy = wireguard, section-name=${section_name}

[WireGuard ${section_name}]
private-key = ${p_privatekey}
self-ip = 10.89.64.2
self-ip-v6 = fd10::2
dns-server = 1.1.1.1, 2606:4700:4700::1111
mtu = 1280
peer = (public-key = ${i_publickey}, allowed-ips = "0.0.0.0/0, ::0/0", endpoint = ${endpoint}:${wg_port}, keepalive = 25)
EOF
echo "WireGuard 安装成功"
echo "客户端配置: "
echo "Self IPv4: 10.89.64.2"
echo "Self IPv6: fd10::2"
echo "Private Key: ${p_privatekey}"
echo "Public Key: ${i_publickey}"
echo "Endpoint: ${endpoint}:${wg_port}"
echo "DNS: 1.1.1.1, 2606:4700:4700::1111"
echo "MTU: 1280"
echo "Keepalive: 25"
