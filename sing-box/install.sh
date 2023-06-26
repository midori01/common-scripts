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
read -r -p "请输入节点域名: " naive_domain
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
域名：${naive_domain}
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
            "type": "direct",
            "tag": "direct"
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
echo "SNI: ${naive_domain}"
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
