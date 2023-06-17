# Install
```bash
bash <(curl -sSLf "https://raw.githubusercontent.com/midori01/common-scripts/main/wireguard/install.sh")
```

# Uninstall
```bash
bash <(curl -sSLf "https://raw.githubusercontent.com/midori01/common-scripts/main/wireguard/install.sh") uninstall
```

# Advanced
`Add Peer:`
```bash
bash <(curl -sSLf "https://raw.githubusercontent.com/midori01/common-scripts/main/wireguard/add_peer.sh")
```
`IPv6 Forward:`
```bash
echo net.ipv6.conf.all.forwarding=1 >> /etc/sysctl.conf && sysctl -p
```
`Restart:`
```bash
wg-quick down wg0 && wg-quick up wg0
```
`Status:`
```bash
wg show wg0
```
