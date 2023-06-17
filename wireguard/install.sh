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

if [[ $1 == "uninstall" ]]; then
  uninstall
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
