# Remove Firewall
```bash
bash <(curl -sSLf "https://raw.githubusercontent.com/midori01/common-scripts/main/oracle/firewall.sh")
```

# Remove Oracle Cloud Agent
```bash
snap remove oracle-cloud-agent
```

# Add IPv6 (Debian)
```bash
bash <(curl -sSLf "https://raw.githubusercontent.com/midori01/common-scripts/main/oracle/ipv6.sh")
```

# Check User Email
```bash
curl http://169.254.169.254/opc/v1/instance/definedTags
```

# Keep Alive (CPU)
```bash
bash <(curl -sSLf "https://raw.githubusercontent.com/midori01/common-scripts/main/oracle/keepalive.sh")
```

# SSH
`Enable Root Login:`
```bash
bash <(curl -sSLf "https://raw.githubusercontent.com/midori01/common-scripts/main/oracle/ssh.sh") rootlogin
```
`Enable Password Login:`
```bash
bash <(curl -sSLf "https://raw.githubusercontent.com/midori01/common-scripts/main/oracle/ssh.sh") enablepwd
```
`Disable Password Login:`
```bash
bash <(curl -sSLf "https://raw.githubusercontent.com/midori01/common-scripts/main/oracle/ssh.sh") disablepwd
```
`Add SSH Public Key:`
```bash
bash <(curl -sSLf "https://raw.githubusercontent.com/midori01/common-scripts/main/oracle/ssh.sh") sshkey
```
`Change SSH Port:`
```bash
bash <(curl -sSLf "https://raw.githubusercontent.com/midori01/common-scripts/main/oracle/ssh.sh") port
```
