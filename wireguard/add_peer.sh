#!/bin/bash

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
wg show
