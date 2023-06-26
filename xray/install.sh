#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi
apt install -y uuid-runtime
uninstall() {
  bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove --purge
  echo "Xray-core 已卸载"
}
update() {
  bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install --beta -u root
  echo "Xray-core 已更新"
}
tcp() {
read -r -p "请输入 VMess 端口 (留空默认 1024): " vmess_port
vmess_port=${vmess_port:-1024}
read -r -p "请输入 VMess UUID (留空随机生成): " vmess_uuid
if [[ -z "$vmess_uuid" ]]; then
  vmess_uuid=$(uuidgen)
fi
cat <<EOF
请确认以下配置信息：
端口：${vmess_port}
UUID：${vmess_uuid}
传输：TCP
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
                "network": "tcp",
                "security": "none"
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
echo "传输: TCP"
}
ws() {
read -r -p "请输入 VMess 端口 (留空默认 1024): " vmess_port
vmess_port=${vmess_port:-1024}
read -r -p "请输入 VMess UUID (留空随机生成): " vmess_uuid
if [[ -z "$vmess_uuid" ]]; then
  vmess_uuid=$(uuidgen)
fi
read -r -p "请输入 WebSocket 路径 (留空默认 /): " ws_path
ws_path=${ws_path:-/}
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
}
tls() {
read -r -p "请输入 VMess 端口 (留空默认 1024): " vmess_port
vmess_port=${vmess_port:-1024}
read -r -p "请输入 VMess UUID (留空随机生成): " vmess_uuid
if [[ -z "$vmess_uuid" ]]; then
  vmess_uuid=$(uuidgen)
fi
read -r -p "请输入证书文件路径: " cer_path
read -r -p "请输入私钥文件路径: " key_path
cat <<EOF
请确认以下配置信息：
端口：${vmess_port}
UUID：${vmess_uuid}
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
echo "VMess 安装成功"
echo "客户端连接信息: "
echo "端口: ${vmess_port}"
echo "UUID: ${vmess_uuid}"
echo "传输: TCP"
echo "TLS: Enabled"
}
wss() {
read -r -p "请输入 VMess 端口 (留空默认 1024): " vmess_port
vmess_port=${vmess_port:-1024}
read -r -p "请输入 VMess UUID (留空随机生成): " vmess_uuid
if [[ -z "$vmess_uuid" ]]; then
  vmess_uuid=$(uuidgen)
fi
read -r -p "请输入 WebSocket 路径 (留空默认 /): " ws_path
ws_path=${ws_path:-/}
read -r -p "请输入证书文件路径: " cer_path
read -r -p "请输入私钥文件路径: " key_path
cat <<EOF
请确认以下配置信息：
端口：${vmess_port}
UUID：${vmess_uuid}
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
echo "VMess 安装成功"
echo "客户端连接信息: "
echo "端口: ${vmess_port}"
echo "UUID: ${vmess_uuid}"
echo "传输: WebSocket"
echo "路径: ${ws_path}"
echo "TLS: Enabled"
}
grpc() {
read -r -p "请输入 VMess 端口 (留空默认 1024): " vmess_port
vmess_port=${vmess_port:-1024}
read -r -p "请输入 VMess UUID (留空随机生成): " vmess_uuid
if [[ -z "$vmess_uuid" ]]; then
  vmess_uuid=$(uuidgen)
fi
read -r -p "请输入服务名称（域名）: " service_name
cat <<EOF
请确认以下配置信息：
端口：${vmess_port}
UUID：${vmess_uuid}
传输：gRPC
服务名称：${service_name}
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
                "network": "grpc",
                "security": "none",
                "grpcSettings": {
                    "serviceName": "${service_name}"
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
echo "传输: gRPC"
echo "服务名称: ${service_name}"
}
grpc-tls() {
read -r -p "请输入 VMess 端口 (留空默认 1024): " vmess_port
vmess_port=${vmess_port:-1024}
read -r -p "请输入 VMess UUID (留空随机生成): " vmess_uuid
if [[ -z "$vmess_uuid" ]]; then
  vmess_uuid=$(uuidgen)
fi
read -r -p "请输入服务名称（域名）: " service_name
read -r -p "请输入证书文件路径: " cer_path
read -r -p "请输入私钥文件路径: " key_path
cat <<EOF
请确认以下配置信息：
端口：${vmess_port}
UUID：${vmess_uuid}
传输：gRPC
服务名称：${service_name}
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
                "network": "grpc",
                "security": "tls",
                "grpcSettings": {
                    "serviceName": "${service_name}"
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
echo "VMess 安装成功"
echo "客户端连接信息: "
echo "端口: ${vmess_port}"
echo "UUID: ${vmess_uuid}"
echo "传输: gRPC"
echo "服务名称: ${service_name}"
echo "TLS: Enabled"
}
quic() {
read -r -p "请输入 VMess 端口 (留空默认 1024): " vmess_port
vmess_port=${vmess_port:-1024}
read -r -p "请输入 VMess UUID (留空随机生成): " vmess_uuid
if [[ -z "$vmess_uuid" ]]; then
  vmess_uuid=$(uuidgen)
fi
read -r -p "请输入 QUIC 伪装类型 (可选值：none、srtp、utp、wechat-video、dtls、wireguard，留空默认 none): " obfs
obfs=${obfs:-none}
read -r -p "请输入证书文件路径: " cer_path
read -r -p "请输入私钥文件路径: " key_path
cat <<EOF
请确认以下配置信息：
端口：${vmess_port}
UUID：${vmess_uuid}
传输：QUIC
QUIC 加密：none
QUIC 伪装：${obfs}
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
                "network": "quic",
                "security": "tls",
                "quicSettings": {
                    "security": "none",
                    "header": {
                        "type": "${obfs}"
                    }
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
echo "VMess 安装成功"
echo "客户端连接信息: "
echo "端口: ${vmess_port}"
echo "UUID: ${vmess_uuid}"
echo "传输: QUIC"
echo "QUIC 加密: none"
echo "QUIC 伪装: ${obfs}"
echo "TLS: Enabled"
}
vless() {
read -r -p "请输入 VLESS 端口 (留空默认 1024): " vless_port
vless_port=${vless_port:-1024}
read -r -p "请输入 VLESS 密码 (留空随机生成): " vless_uuid
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
}
trojan-tcp() {
read -r -p "请输入 Trojan 端口 (留空默认 1024): " trojan_port
trojan_port=${trojan_port:-1024}
read -r -p "请输入 Trojan 密码 (留空随机生成): " trojan_password
if [[ -z "$trojan_password" ]]; then
  trojan_password=$(openssl rand -base64 16)
fi
read -r -p "请输入证书文件路径: " cer_path
read -r -p "请输入私钥文件路径: " key_path
cat <<EOF
请确认以下配置信息：
端口：${trojan_port}
密码：${trojan_password}
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
trojan-ws() {
read -r -p "请输入 Trojan 端口 (留空默认 1024): " trojan_port
trojan_port=${trojan_port:-1024}
read -r -p "请输入 Trojan 密码 (留空随机生成): " trojan_password
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
if [[ $1 == "tls" ]]; then
  tls
  exit 0
fi
if [[ $1 == "wss" ]]; then
  wss
  exit 0
fi
if [[ $1 == "grpc" ]]; then
  grpc
  exit 0
fi
if [[ $1 == "grpc-tls" ]]; then
  grpc-tls
  exit 0
fi
if [[ $1 == "quic" ]]; then
  quic
  exit 0
fi
if [[ $1 == "vless" ]]; then
  vless
  exit 0
fi
if [[ $1 == "trojan-tpc" ]]; then
  trojan-tcp
  exit 0
fi
if [[ $1 == "trojan-ws" ]]; then
  trojan-ws
  exit 0
fi
