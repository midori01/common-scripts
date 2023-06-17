#!/bin/bash

read -r -p "请输入备注: " note
read -r -p "请输入 Peer Public Key: " peer_public_key
read -r -p "请输入 Peer Self IPv4: " peer_self_ipv4
read -r -p "请输入 Peer Self IPv6: " peer_self_ipv6
echo "" >> /etc/wireguard/wg0.conf
echo "# ${note}" >> /etc/wireguard/wg0.conf
echo "[Peer]" >> /etc/wireguard/wg0.conf
echo "PublicKey = ${peer_public_key}" >> /etc/wireguard/wg0.conf
echo "AllowedIPs = ${peer_self_ipv4}/32, ${peer_self_ipv6}/128" >> /etc/wireguard/wg0.conf
wg syncconf wg0 <(wg-quick strip wg0)
