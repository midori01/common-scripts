# Oralce Common
`Remove Firewall (Ubuntu):`
```bash
bash <(curl -sSLf "https://raw.githubusercontent.com/midori01/common-scripts/main/oracle/firewall.sh")
```
`Remove Monitor (Ubuntu):`
```bash
snap remove oracle-cloud-agent
```
`Add IPv6 (Debian):`
```bash
bash <(curl -sSLf "https://raw.githubusercontent.com/midori01/common-scripts/main/oracle/ipv6.sh")
```
`Check User Email:`
```bash
curl http://169.254.169.254/opc/v1/instance/definedTags
```