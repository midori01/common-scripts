#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi
if ! command -v wget &> /dev/null; then
  echo "wget 未安装，请安装后再运行脚本"
  exit 1
fi
if [[ "$(uname -m)" == "x86_64" ]]; then
  type="amd64"
elif [[ "$(uname -m)" == "aarch64" ]]; then
  type="arm64"
else
  echo "$(uname -m) 架构不支持"
  exit 1
fi
latest_version=$(curl -m 10 -sL "https://api.github.com/repos/SagerNet/sing-box/releases/latest" | awk -F'"' '/tag_name/{gsub(/v/, "", $4); print $4}')
package_name=sing-box-${latest_version}-linux-${type}
download_url=https://github.com/SagerNet/sing-box/releases/download/v${latest_version}/${package_name}.tar.gz
uninstall() {
  systemctl stop sing-box.service
  systemctl disable sing-box.service
  rm -f /etc/systemd/system/sing-box.service
  rm -f /etc/sing-box.json
  rm -f /usr/local/bin/sing-box
  echo "sing-box 已卸载"
}
update() {
  rm -f /usr/local/bin/sing-box
  wget -N --no-check-certificate ${download_url}
  tar zxvf ${package_name}.tar.gz
  mv ${package_name}/sing-box /usr/local/bin/sing-box
  chmod +x /usr/local/bin/sing-box
  rm -r ${package_name}
  rm -f ${package_name}.tar.gz
  systemctl restart sing-box.service
  echo "sing-box 已更新"
}
naive() {
read -r -p "请输入证书路径: " cer_path
read -r -p "请输入私钥路径: " key_path
read -r -p "请输入节点端口 (留空默认 8964): " naive_port
naive_port=${naive_port:-8964}
read -r -p "请输入用户名 (留空随机生成): " naive_user
if [[ -z "$naive_user" ]]; then
  naive_user=$(openssl rand -hex 8)
fi
read -r -p "请输入密码 (留空随机生成): " naive_pass
if [[ -z "$naive_pass" ]]; then
  naive_pass=$(openssl rand -hex 8)
fi
cat <<EOF
请确认以下配置信息：
端口：${naive_port}
用户名：${naive_user}
密码：${naive_pass}
证书路径：${cer_path}
私钥路径：${key_path}
EOF
read -r -p "确认无误？(Y/N)" confirm
case "$confirm" in
  [yY]) ;;
  *) echo "已取消安装"; exit 0;;
esac
wget -N --no-check-certificate ${download_url}
tar zxvf ${package_name}.tar.gz
mv ${package_name}/sing-box /usr/local/bin/sing-box
chmod +x /usr/local/bin/sing-box
rm -r ${package_name}
rm -f ${package_name}.tar.gz
cat > /etc/systemd/system/sing-box.service <<EOF
[Unit]
After=network.target nss-lookup.target

[Service]
User=root
WorkingDirectory=/usr/local/bin
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
ExecStart=/usr/local/bin/sing-box run -c /etc/sing-box.json
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=10
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF
cat > /etc/sing-box.json <<EOF
{
    "log": {
        "level": "info",
        "timestamp": true
    },
    "inbounds": [
        {
            "type": "naive",
            "listen": "::",
            "listen_port": ${naive_port},
            "users": [
                {
                    "username": "${naive_user}",
                    "password": "${naive_pass}"
                }
            ],
            "tls": {
                "enabled": true,
                "certificate_path": "${cer_path}",
                "key_path": "${key_path}"
            }
        }
    ],
    "outbounds": [
        {
            "type": "direct"
        }
    ]
}
EOF
systemctl daemon-reload
systemctl start sing-box.service
systemctl enable sing-box.service
echo "NaïveProxy 安装成功"
echo "客户端连接信息: "
echo "端口: ${naive_port}"
echo "用户名: ${naive_user}"
echo "密码: ${naive_pass}"
echo "Padding: Enabled"
}
hy() {
read -r -p "请输入证书路径: " cer_path
read -r -p "请输入私钥路径: " key_path
read -r -p "请输入节点端口 (留空默认 8964): " hy_port
hy_port=${hy_port:-8964}
read -r -p "请输入密码 (留空随机生成): " hy_pass
if [[ -z "$hy_pass" ]]; then
  hy_pass=$(openssl rand -hex 8)
fi
cat <<EOF
请确认以下配置信息：
端口：${hy_port}
密码：${hy_pass}
证书路径：${cer_path}
私钥路径：${key_path}
EOF
read -r -p "确认无误？(Y/N)" confirm
case "$confirm" in
  [yY]) ;;
  *) echo "已取消安装"; exit 0;;
esac
wget -N --no-check-certificate ${download_url}
tar zxvf ${package_name}.tar.gz
mv ${package_name}/sing-box /usr/local/bin/sing-box
chmod +x /usr/local/bin/sing-box
rm -r ${package_name}
rm -f ${package_name}.tar.gz
cat > /etc/systemd/system/sing-box.service <<EOF
[Unit]
After=network.target nss-lookup.target

[Service]
User=root
WorkingDirectory=/usr/local/bin
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
ExecStart=/usr/local/bin/sing-box run -c /etc/sing-box.json
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=10
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF
cat > /etc/sing-box.json <<EOF
{
    "log": {
        "level": "info",
        "timestamp": true
    },
    "inbounds": [
        {
            "type": "hysteria",
            "listen": "::",
            "listen_port": ${hy_port},
            "up_mbps": 100,
            "down_mbps": 100,
            "users": [
                {
                    "auth_str": "${hy_pass}"
                }
            ],
            "tls": {
                "enabled": true,
                "alpn": [ "h3" ],
                "certificate_path": "${cer_path}",
                "key_path": "${key_path}"
            }
        }
    ],
    "outbounds": [
        {
            "type": "direct"
        }
    ]
}
EOF
systemctl daemon-reload
systemctl start sing-box.service
systemctl enable sing-box.service
echo "Hysteria 安装成功"
echo "客户端连接信息: "
echo "端口: ${hy_port}"
echo "密码: ${hy_pass}"
echo "ALPN: h3"
}
trojan() {
read -r -p "请输入证书路径: " cer_path
read -r -p "请输入私钥路径: " key_path
read -r -p "请输入节点端口 (留空默认 8964): " trojan_port
trojan_port=${trojan_port:-8964}
read -r -p "请输入密码 (留空随机生成): " trojan_pass
if [[ -z "$trojan_pass" ]]; then
  trojan_pass=$(openssl rand -hex 8)
fi
cat <<EOF
请确认以下配置信息：
端口：${trojan_port}
密码：${trojan_pass}
证书路径：${cer_path}
私钥路径：${key_path}
EOF
read -r -p "确认无误？(Y/N)" confirm
case "$confirm" in
  [yY]) ;;
  *) echo "已取消安装"; exit 0;;
esac
wget -N --no-check-certificate ${download_url}
tar zxvf ${package_name}.tar.gz
mv ${package_name}/sing-box /usr/local/bin/sing-box
chmod +x /usr/local/bin/sing-box
rm -r ${package_name}
rm -f ${package_name}.tar.gz
cat > /etc/systemd/system/sing-box.service <<EOF
[Unit]
After=network.target nss-lookup.target

[Service]
User=root
WorkingDirectory=/usr/local/bin
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
ExecStart=/usr/local/bin/sing-box run -c /etc/sing-box.json
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=10
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF
cat > /etc/sing-box.json <<EOF
{
    "log": {
        "level": "info",
        "timestamp": true
    },
    "inbounds": [
        {
            "type": "trojan",
            "listen": "::",
            "listen_port": ${trojan_port},
            "users": [
                {
                    "password": "${trojan_pass}"
                }
            ],
            "tls": {
                "enabled": true,
                "certificate_path": "${cer_path}",
                "key_path": "${key_path}"
            }
        }
    ],
    "outbounds": [
        {
            "type": "direct"
        }
    ]
}
EOF
systemctl daemon-reload
systemctl start sing-box.service
systemctl enable sing-box.service
echo "Trojan 安装成功"
echo "客户端连接信息: "
echo "端口: ${trojan_port}"
echo "密码: ${trojan_pass}"
}
vmess() {
read -r -p "请输入节点端口 (留空默认 8964): " vmess_port
vmess_port=${vmess_port:-8964}
wget -N --no-check-certificate ${download_url}
tar zxvf ${package_name}.tar.gz
mv ${package_name}/sing-box /usr/local/bin/sing-box
chmod +x /usr/local/bin/sing-box
rm -r ${package_name}
rm -f ${package_name}.tar.gz
cat > /etc/systemd/system/sing-box.service <<EOF
[Unit]
After=network.target nss-lookup.target

[Service]
User=root
WorkingDirectory=/usr/local/bin
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
ExecStart=/usr/local/bin/sing-box run -c /etc/sing-box.json
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=10
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF
vmess_pass=$(/usr/local/bin/sing-box generate uuid)
cat > /etc/sing-box.json <<EOF
{
    "log": {
        "level": "info",
        "timestamp": true
    },
    "inbounds": [
        {
            "type": "vmess",
            "listen": "::",
            "listen_port": ${vmess_port},
            "users": [
                {
                    "uuid": "${vmess_pass}",
                    "alterId": 0
                }
            ]
        }
    ],
    "outbounds": [
        {
            "type": "direct"
        }
    ]
}
EOF
systemctl daemon-reload
systemctl start sing-box.service
systemctl enable sing-box.service
echo "VMess 安装成功"
echo "客户端连接信息: "
echo "端口: ${vmess_port}"
echo "UUID: ${vmess_pass}"
}
vless() {
read -r -p "请输入节点端口 (留空默认 8964): " vless_port
vless_port=${vless_port:-8964}
read -r -p "请输入握手 SNI (不懂请留空): " vless_sni
vless_sni=${vless_sni:-www.iq.com}
cat <<EOF
请确认以下配置信息：
端口：${vless_port}
SNI：${vless_sni}
EOF
read -r -p "确认无误？(Y/N)" confirm
case "$confirm" in
  [yY]) ;;
  *) echo "已取消安装"; exit 0;;
esac
wget -N --no-check-certificate ${download_url}
tar zxvf ${package_name}.tar.gz
mv ${package_name}/sing-box /usr/local/bin/sing-box
chmod +x /usr/local/bin/sing-box
rm -r ${package_name}
rm -f ${package_name}.tar.gz
cat > /etc/systemd/system/sing-box.service <<EOF
[Unit]
After=network.target nss-lookup.target

[Service]
User=root
WorkingDirectory=/usr/local/bin
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
ExecStart=/usr/local/bin/sing-box run -c /etc/sing-box.json
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=10
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF
vless_pass=$(/usr/local/bin/sing-box generate uuid)
vless_sid=$(/usr/local/bin/sing-box generate rand --hex 8)
output=$(/usr/local/bin/sing-box generate reality-keypair)
vless_prikey=$(echo "$output" | awk '/PrivateKey:/ {print $2}')
vless_pubkey=$(echo "$output" | awk '/PublicKey:/ {print $2}')
cat > /etc/sing-box.json <<EOF
{
    "log": {
        "level": "info",
        "timestamp": true
    },
    "inbounds": [
        {
            "type": "vless",
            "listen": "::",
            "listen_port": ${vless_port},
            "users": [
                {
                    "uuid": "${vless_pass}",
                    "flow": "xtls-rprx-vision"
                }
            ],
            "tls": {
                "enabled": true,
                "server_name": "${vless_sni}",
                "reality": {
                    "enabled": true,
                    "handshake": {
                        "server": "${vless_sni}",
                        "server_port": 443
                    },
                    "private_key": "${vless_prikey}",
                    "short_id": [
                        "${vless_sid}"
                    ]
                }
            }
        }
    ],
    "outbounds": [
        {
            "type": "direct"
        }
    ]
}
EOF
systemctl daemon-reload
systemctl start sing-box.service
systemctl enable sing-box.service
echo "VLESS 安装成功"
echo "客户端连接信息: "
echo "端口: ${vless_port}"
echo "UUID: ${vless_pass}"
echo "SNI: ${vless_sni}"
echo "XTLS Flow: xtls-rprx-vision"
echo "Reality Public Key: ${vless_pubkey}"
echo "Reality Short ID: ${vless_sid}"
}
ss() {
read -r -p "请输入节点端口 (留空默认 8964): " ss_port
ss_port=${ss_port:-8964}
ss_pass=$(openssl rand -base64 16)
wget -N --no-check-certificate ${download_url}
tar zxvf ${package_name}.tar.gz
mv ${package_name}/sing-box /usr/local/bin/sing-box
chmod +x /usr/local/bin/sing-box
rm -r ${package_name}
rm -f ${package_name}.tar.gz
cat > /etc/systemd/system/sing-box.service <<EOF
[Unit]
After=network.target nss-lookup.target

[Service]
User=root
WorkingDirectory=/usr/local/bin
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
ExecStart=/usr/local/bin/sing-box run -c /etc/sing-box.json
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=10
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF
cat > /etc/sing-box.json <<EOF
{
    "log": {
        "level": "info",
        "timestamp": true
    },
    "inbounds": [
        {
            "type": "shadowsocks",
            "listen": "::",
            "listen_port": ${ss_port},
            "method": "2022-blake3-aes-128-gcm",
            "password": "${ss_pass}"
        }
    ],
    "outbounds": [
        {
            "type": "direct"
        }
    ]
}
EOF
systemctl daemon-reload
systemctl start sing-box.service
systemctl enable sing-box.service
echo "Shadowsocks 2022 安装成功"
echo "客户端连接信息: "
echo "端口: ${ss_port}"
echo "密码: ${ss_pass}"
echo "加密: 2022-blake3-aes-128-gcm"
}
if [[ $1 == "uninstall" ]]; then
  uninstall
  exit 0
fi
if [[ $1 == "update" ]]; then
  update
  exit 0
fi
if [[ $1 == "naive" ]]; then
  naive
  exit 0
fi
if [[ $1 == "hy" ]]; then
  hy
  exit 0
fi
if [[ $1 == "trojan" ]]; then
  trojan
  exit 0
fi
if [[ $1 == "vmess" ]]; then
  vmess
  exit 0
fi
if [[ $1 == "vless" ]]; then
  vless
  exit 0
fi
if [[ $1 == "ss" ]]; then
  ss
  exit 0
fi
