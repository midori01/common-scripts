#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi

if ! command -v wget &> /dev/null; then
  echo "wget 未安装，请安装后再运行脚本"
  exit 1
fi

uninstall() {
  systemctl stop tuic.service
  systemctl disable tuic.service
  rm -f /etc/systemd/system/tuic.service
  rm -f /etc/tuic-server.json
  rm -f /usr/local/bin/tuic-server
  echo "TUIC 已卸载"
}

update() {
  rm -f /usr/local/bin/tuic-server
  wget -O /usr/local/bin/tuic-server https://github.com/EAimTY/tuic/releases/download/${latest_version}/${latest_version}-${type}-unknown-linux-musl
  chmod +x /usr/local/bin/tuic-server
  systemctl restart tuic.service
  echo "TUIC 已更新"
}

if [[ $1 == "uninstall" ]]; then
  uninstall
  exit 0
fi

if [[ $1 == "update" ]]; then
  update
  exit 0
fi

latest_version=$(curl -m 10 -sL "https://api.github.com/repos/EAimTY/tuic/releases" | awk -F'"' '/"tag_name": "tuic-server-/{print $4; exit}')

if [[ "$(uname -m)" == "x86_64" ]]; then
  type="x86_64"
elif [[ "$(uname -m)" == "aarch64" ]]; then
  type="aarch64"
else
  echo "$(uname -m) 架构不支持"
  exit 1
fi

read -r -p "请输入 TUIC 端口 (留空默认 443): " listen_port
listen_port=${listen_port:-443}

read -r -p "请输入 TUIC UUID (留空将使用 00000000-0000-0000-0000-000000000000): " tuic_uuid
tuic_uuid=${tuic_uuid:-00000000-0000-0000-0000-000000000000}

read -r -p "请输入 TUIC 密码 (留空随机生成): " token
if [[ -z "$token" ]]; then
  token=$(openssl rand -base64 32)
fi

read -r -p "请输入证书文件路径: " cer_path
read -r -p "请输入私钥文件路径: " key_path

cat <<EOF
请确认以下配置信息：
监听端口：${listen_port}
UUID：${tuic_uuid}
密码：${token}
证书路径：${cer_path}
私钥路径：${key_path}
EOF
read -r -p "确认无误？(Y/N)" confirm
case "$confirm" in
  [yY]) ;;
  *) echo "已取消安装"; exit 0;;
esac

wget -O /usr/local/bin/tuic-server https://github.com/EAimTY/tuic/releases/download/${latest_version}/${latest_version}-${type}-unknown-linux-musl
chmod +x /usr/local/bin/tuic-server

cat > /etc/systemd/system/tuic.service <<EOF
[Unit]
Description=TUIC Server Service
After=network.target

[Service]
Type=simple
User=root
Group=nogroup
LimitNOFILE=32768
ExecStart=/usr/local/bin/tuic-server -c /etc/tuic-server.json
StandardOutput=null
StandardError=null
SyslogIdentifier=tuic-server

[Install]
WantedBy=multi-user.target
EOF
cat > /etc/tuic-server.json <<EOF
{ 
  "server": "[::]:${listen_port}",
  "users": {
    "$tuic_uuid": "${token}"
  },
  "certificate": "${cer_path}",
  "private_key": "${key_path}",
  "congestion_control": "bbr",
  "alpn": ["h3"],
  "udp_relay_ipv6": true,
  "zero_rtt_handshake": false,
  "dual_stack": true,
  "auth_timeout": "3s",
  "task_negotiation_timeout": "3s",
  "max_idle_time": "10s",
  "max_external_packet_size": 1500,
  "send_window": 16777216,
  "receive_window": 8388608,
  "gc_interval": "3s",
  "gc_lifetime": "15s",
  "log_level": "warn"
}
EOF

systemctl daemon-reload
systemctl enable tuic.service
systemctl start tuic.service

echo "TUIC 安装成功"
echo "客户端连接信息: "
echo "连接端口: ${listen_port}"
echo "UUID: ${tuic_uuid}"
echo "密码: ${token}"
echo "ALPN: h3"
echo "流控模式: bbr"
echo "协议版本: v5"
