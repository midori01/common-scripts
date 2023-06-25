#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi
apt install -y uuid-runtime
uninstall() {
  bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove --purge
  echo "VLESS 已卸载"
}
update() {
  bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install --beta -u root
  echo "VLESS 已更新"
}
if [[ $1 == "uninstall" ]]; then
  uninstall
  exit 0
fi
if [[ $1 == "update" ]]; then
  update
  exit 0
fi
read -r -p "请输入端口 (留空默认 1024): " vless_port
vless_port=${vless_port:-1024}
read -r -p "请输入 UUID (留空随机生成): " vless_uuid
if [[ -z "$vless_uuid" ]]; then
  vless_uuid=$(uuidgen)
fi
read -r -p "请输入 SNI 域名 (留空默认 www.iq.com): " sni_domain
sni_domain=${sni_domain:-www.iq.com}
cat <<EOF
请确认以下配置信息：
端口：${vless_port}
UUID：${vless_uuid}
SNI：${sni_domain}
EOF
read -r -p "确认无误？(Y/N)" confirm
case "$confirm" in
  [yY]) ;;
  *) echo "已取消安装"; exit 0;;
esac
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install --beta -u root
output=$(/usr/local/bin/xray x25519)
privatekey=$(echo "$output" | awk '/Private key:/ {print $NF}')
publickey=$(echo "$output" | awk '/Public key:/ {print $NF}')
shortid=$(openssl rand -hex 8)
cat > /usr/local/etc/xray/config.json <<EOF
{
    "log": {
        "loglevel": "warning"
    },
    "routing": {
        "domainStrategy": "AsIs"
    },
    "inbounds": [
        {
            "listen": "0.0.0.0",
            "port": ${vless_port},
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "${vless_uuid}",
                        "flow": "xtls-rprx-vision"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "show": false,
                    "dest": "${sni_domain}:443",
                    "xver": 0,
                    "serverNames": ["${sni_domain}"],
                    "privateKey": "${privatekey}",
                    "shortIds": ["${shortid}"]
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "settings": {
                "domainStrategy": "UseIPv4"
            }
        }
    ]
}
EOF
systemctl restart xray.service
echo "VLESS REALITY 安装成功"
echo "客户端连接信息: "
echo "端口: ${vless_port}"
echo "UUID: ${vless_uuid}"
echo "传输: TCP"
echo "Flow: xtls-rprx-vision"
echo "Public Key: ${publickey}"
echo "Short ID: ${shortid}"
echo "SNI: ${sni_domain}"
