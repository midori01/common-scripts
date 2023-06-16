#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi

apt install -y uuid-runtime

uninstall() {
  bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove --purge
  echo "VMess 已卸载"
}

update() {
  bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install --beta -u root
  echo "VMess 已更新"
}

if [[ $1 == "uninstall" ]]; then
  uninstall
  exit 0
fi

if [[ $1 == "update" ]]; then
  update
  exit 0
fi

read -r -p "请输入 VMess 端口 (留空默认 1024): " vmess_port
vmess_port=${vmess_port:-1024}

read -r -p "请输入 VMess UUID (留空随机生成): " vmess_uuid
if [[ -z "$vmess_uuid" ]]; then
  vmess_uuid=$(uuidgen)
fi

read -r -p "请输入 WebSocket 路径 (留空默认 /): " ws_path
ws_path =${ws_path:-/}

cat <<EOF
请确认以下配置信息：
端口：${vmess_port}
UUID：${vmess_uuid}
传输：WebSocket
路径：${ws_path}
EOF
read -r -p "确认无误？(Y/N)" confirm
case "$confirm" in
  [yY]) ;;
  *) echo "已取消安装"; exit 0;;
esac

bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install --beta -u root

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
            "port": ${vmess_port},
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "${vmess_uuid}"
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "path": "${ws_path}"
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

echo "VMess 安装成功"
echo "客户端连接信息: "
echo "端口: ${vmess_port}"
echo "UUID: ${vmess_uuid}"
echo "传输: WebSocket"
echo "路径: ${ws_path}"
