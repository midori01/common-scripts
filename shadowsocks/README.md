# Usually
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

# Advanced
`Install simple-obfs plugin`
```bash
bash <(curl -sSLf "https://raw.githubusercontent.com/midori01/common-scripts/main/shadowsocks/install.sh") obfs
```
> _Don’t use it if you don’t understand._

<br>

`Upgrade to full-extra version`
```bash
bash <(curl -sSLf "https://raw.githubusercontent.com/midori01/common-scripts/main/shadowsocks/install.sh") update full-extra
```
> _Built by Midori with the full-extra option._
