`Install`
```bash
bash <(curl -sSLf "https://raw.githubusercontent.com/midori01/common-scripts/main/shadowsocks/install.sh")
```
`Update`
```bash
bash <(curl -sSLf "https://raw.githubusercontent.com/midori01/common-scripts/main/shadowsocks/install.sh") update
```
`Uninstall`
```bash
bash <(curl -sSLf "https://raw.githubusercontent.com/midori01/common-scripts/main/shadowsocks/install.sh") uninstall
```
`Restart`
```bash
systemctl restart ss-rust
```
`Status`
```bash
systemctl status ss-rust
```
`Configuration file path`
```bash
/etc/ss-rust.json
```

<br>

`Install simple-obfs plugin`  
> _Don’t use it if you don’t understand._
```bash
bash <(curl -sSLf "https://raw.githubusercontent.com/midori01/common-scripts/main/shadowsocks/install.sh") obfs
```
