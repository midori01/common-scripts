# Usage
`Install:`
```bash
bash <(curl -sSLf "https://raw.githubusercontent.com/midori01/common-scripts/main/wireguard/install.sh")
```
`Restart:`
```bash
wg-quick down wg0 && wg-quick up wg0
```
`Check Status:`
```bash
wg show wg0
```
`View Surge Configuration:`
```bash
cat /etc/wireguard/wg_surge.conf
```
`Uninstall:`
```bash
bash <(curl -sSLf "https://raw.githubusercontent.com/midori01/common-scripts/main/wireguard/install.sh") uninstall
```

# Advanced
`Add Peer:`
```bash
bash <(curl -sSLf "https://raw.githubusercontent.com/midori01/common-scripts/main/wireguard/install.sh") peer
```
`Enable IPv6 Forward:`
```bash
echo net.ipv6.conf.all.forwarding=1 >> /etc/sysctl.conf && sysctl -p
```
