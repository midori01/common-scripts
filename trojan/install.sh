#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi
uninstall() {
  bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove --purge
  echo "Trojan 已卸载"
}
update() {
  bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install --beta -u root
  echo "Trojan 已更新"
}
tcp() {
read -r -p "请输入端口 (留空默认 8964): " trojan_port
trojan_port=${trojan_port:-8964}
read -r -p "请输入密码 (留空随机生成): " trojan_password
if [[ -z "$trojan_password" ]]; then
  trojan_password=$(openssl rand -base64 16)
fi
read -r -p "请输入证书文件路径: " cer_path
read -r -p "请输入私钥文件路径: " key_path
cat <<EOF
请确认以下配置信息：
端口：${trojan_port}
密码：${trojan_uuid}
传输：TCP
证书路径：${cer_path}
私钥路径：${key_path}
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
            "port": ${trojan_port},
            "protocol": "trojan",
            "settings": {
                "clients": [
                    {
                        "password": "${trojan_password}"
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "tls",
                "tlsSettings": {
                    "certificates": [
                        {
                            "certificateFile": "${cer_path}",
                            "keyFile": "${key_path}"
                        }
                    ]
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
echo "Trojan 安装成功"
echo "客户端连接信息: "
echo "端口: ${trojan_port}"
echo "密码: ${trojan_password}"
echo "传输: TCP"
}
ws() {
read -r -p "请输入端口 (留空默认 8964): " trojan_port
trojan_port=${trojan_port:-8964}
read -r -p "请输入密码 (留空随机生成): " trojan_password
if [[ -z "$trojan_password" ]]; then
  trojan_password=$(openssl rand -base64 16)
fi
read -r -p "请输入 WebSocket 路径 (留空默认 /): " ws_path
ws_path=${ws_path:-/}
read -r -p "请输入证书文件路径: " cer_path
read -r -p "请输入私钥文件路径: " key_path
cat <<EOF
请确认以下配置信息：
端口：${trojan_port}
密码：${trojan_password}
传输：WebSocket
路径：${ws_path}
证书路径：${cer_path}
私钥路径：${key_path}
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
            "port": ${trojan_port},
            "protocol": "trojan",
            "settings": {
                "clients": [
                    {
                        "password": "${trojan_password}"
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "security": "tls",
                "wsSettings": {
                    "path": "${ws_path}"
                },
                "tlsSettings": {
                    "certificates": [
                        {
                            "certificateFile": "${cer_path}",
                            "keyFile": "${key_path}"
                        }
                    ]
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
echo "Trojan 安装成功"
echo "客户端连接信息: "
echo "端口: ${trojan_port}"
echo "密码: ${trojan_password}"
echo "传输: WebSocket"
echo "路径: ${ws_path}"
}
if [[ $1 == "uninstall" ]]; then
  uninstall
  exit 0
fi
if [[ $1 == "update" ]]; then
  update
  exit 0
fi
if [[ $1 == "tcp" ]]; then
  tcp
  exit 0
fi
if [[ $1 == "ws" ]]; then
  ws
  exit 0
fi
