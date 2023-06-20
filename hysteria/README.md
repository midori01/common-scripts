# Usage
`Install:`
```bash
bash <(curl -sSLf "https://raw.githubusercontent.com/midori01/common-scripts/main/hysteria/install.sh")
```
`Update:`
```bash
bash <(curl -sSLf "https://raw.githubusercontent.com/midori01/common-scripts/main/hysteria/install.sh") update
```
`Uninstall:`
```bash
bash <(curl -sSLf "https://raw.githubusercontent.com/midori01/common-scripts/main/hysteria/install.sh") uninstall
```

# Advanced
`Port Hopping:`
```bash
bash <(curl -sSLf "https://raw.githubusercontent.com/midori01/common-scripts/main/hysteria/install.sh") hopping
```
`Optimization:`
```bash
sysctl -w net.core.rmem_max=16777216
sysctl -w net.core.wmem_max=16777216
sysctl -p
```
