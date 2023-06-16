# Remove Firewall
```bash
bash <(curl -sSLf "https://raw.githubusercontent.com/midori01/common-scripts/main/oracle/firewall.sh")
```

# Remove Oracle Cloud Agent
```bash
snap remove oracle-cloud-agent
```

# Check User Email
```bash
curl http://169.254.169.254/opc/v1/instance/definedTags
```

# Keep Alive
```bash
bash <(curl -sSLf "https://raw.githubusercontent.com/midori01/common-scripts/main/oracle/keepalive.sh")
```
