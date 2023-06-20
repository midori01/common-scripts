#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi
if ! command -v wget &> /dev/null; then
  echo "wget 未安装，请安装后再运行脚本"
  exit 1
fi
latest_version=$(curl -m 10 -sL "https://api.github.com/repos/apernet/hysteria/releases/latest" | awk -F'"' '/tag_name/{print $4}')
if [[ "$(uname -m)" == "x86_64" ]]; then
  type="amd64"
elif [[ "$(uname -m)" == "aarch64" ]]; then
 type="arm64"
else
  echo "$(uname -m) 架构不支持"
  exit 1
fi
uninstall() {
  systemctl stop hysteria.service
  systemctl disable hysteria.service
  rm -f /etc/systemd/system/hysteria.service
  rm -f /etc/hysteria.json
  rm -f /usr/local/bin/hysteria
  echo "Hysteria 已卸载"
}
update() {
  rm -f /usr/local/bin/hysteria
  wget -O /usr/local/bin/hysteria "https://github.com/apernet/hysteria/releases/download/${latest_version}/hysteria-linux-${type}"
  chmod +x /usr/local/bin/hysteria
  systemctl restart hysteria.service
  echo "Hysteria 已更新"
}
if [[ $1 == "uninstall" ]]; then
  uninstall
  exit 0
fi
if [[ $1 == "update" ]]; then
  update
  exit 0
fi
read -r -p "请输入 Hysteria 端口 (留空默认 8888): " port
port=${port:-8888}
read -r -p "请输入 Hysteria 密码 (留空随机生成): " password
if [[ -z "$password" ]]; then
  password=$(openssl rand -base64 32)
fi
read -r -p "请输入 Hysteria 混淆 (可选，不使用请留空): " obfs
read -r -p "请输入证书文件路径: " cer_path
read -r -p "请输入私钥文件路径: " key_path
cat <<EOF
请确认以下配置信息：
端口：${port}
密码：${password}
混淆：${obfs}
证书路径：${cer_path}
私钥路径：${key_path}
EOF
read -r -p "确认无误？(Y/N)" confirm
case "$confirm" in
  [yY]) ;;
  *) echo "已取消安装"; exit 0;;
esac
wget -O /usr/local/bin/hysteria "https://github.com/apernet/hysteria/releases/download/${latest_version}/hysteria-linux-${type}"
chmod +x /usr/local/bin/hysteria
cat > /etc/systemd/system/hysteria.service <<EOF
[Unit]
Description=hysteria service
After=network.target

[Service]
Type=simple
User=root
Group=nogroup
LimitNOFILE=32768
ExecStart=/usr/local/bin/hysteria -c /etc/hysteria.json server
StandardOutput=null
StandardError=null
SyslogIdentifier=hysteria

[Install]
WantedBy=multi-user.target
EOF
cat > /etc/hysteria.json <<EOF
{
  "listen": ":${port}",
  "protocol": "udp",
  "cert": "${cer_path}",
  "key": "${key_path}",
  "disable_udp": false,
  "obfs": "${obfs}",
  "auth": {
    "mode": "passwords",
    "config": ["${password}"]
  },
  "alpn": "h3",
  "recv_window_conn": 15728640,
  "recv_window_client": 67108864,
  "max_conn_client": 4096,
  "disable_mtu_discovery": false,
  "resolver": "udp://1.1.1.1:53",
  "resolve_preference": "46"
}
EOF
systemctl daemon-reload
systemctl start hysteria.service
systemctl enable hysteria.service
echo "Hysteria 安装成功"
echo "客户端连接信息: "
echo "端口: ${port}"
echo "密码: ${password}"
echo "混淆: ${obfs}"
echo "ALPN: h3"
