#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi
if ! command -v wget &> /dev/null; then
  echo "wget 未安装，请安装后再运行脚本"
  exit 1
fi
latest_version=$(curl -m 10 -sL "https://api.github.com/repos/klzgrad/forwardproxy/releases/latest" | awk -F'"' '/tag_name/{print $4}')
uninstall() {
  rm -r /var/www/html
  apt purge -y caddy
  apt autoremove -y
  rm -f /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  rm -f /etc/apt/sources.list.d/caddy-stable.list
  echo "NaïveProxy 已卸载"
}
update() {
  rm -f /usr/bin/caddy
  wget https://github.com/klzgrad/forwardproxy/releases/download/${latest_version}/caddy-forwardproxy-naive.tar.xz
  tar -xf caddy-forwardproxy-naive.tar.xz
  cp caddy-forwardproxy-naive/caddy /usr/bin/caddy
  chmod +x /usr/bin/caddy
  rm -r caddy-forwardproxy-naive
  rm -f caddy-forwardproxy-naive.tar.xz
  systemctl restart caddy.service
  echo "NaïveProxy 已更新"
}
if [[ $1 == "uninstall" ]]; then
  uninstall
  exit 0
fi
if [[ $1 == "update" ]]; then
  update
  exit 0
fi
read -r -p "请输入节点域名: " naive_domain
read -r -p "请输入节点端口 (留空默认 8964): " naive_port
naive_port=${naive_port:-8964}
read -r -p "请输入节点用户名 (留空随机生成): " naive_user
if [[ -z "$naive_user" ]]; then
  naive_user=$(openssl rand -hex 8)
fi
read -r -p "请输入节点密码 (留空随机生成): " naive_pass
if [[ -z "$naive_pass" ]]; then
  naive_pass=$(openssl rand -hex 16)
fi
cat <<EOF
请确认以下配置信息：
域名：${naive_domain}
端口：${naive_port}
用户名：${naive_user}
密码：${naive_pass}
EOF
read -r -p "确认无误？(Y/N)" confirm
case "$confirm" in
  [yY]) ;;
  *) echo "已取消安装"; exit 0;;
esac
apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt update
apt install -y caddy
wget https://github.com/klzgrad/forwardproxy/releases/download/${latest_version}/caddy-forwardproxy-naive.tar.xz
tar -xf caddy-forwardproxy-naive.tar.xz
cp caddy-forwardproxy-naive/caddy /usr/bin/caddy
chmod +x /usr/bin/caddy
rm -r caddy-forwardproxy-naive
rm -f caddy-forwardproxy-naive.tar.xz
mkdir -p /var/www/html
echo "NMSL" > /var/www/html/index.html
cat > /etc/caddy/Caddyfile <<EOF
:${naive_port}, ${naive_domain}:${naive_port} {
  tls nmsl@wsnd.com
  forward_proxy {
    basic_auth ${naive_user} ${naive_pass}
    hide_ip
    hide_via
    probe_resistance
  }
  file_server {
    root /var/www/html
  }
}
EOF
systemctl restart caddy.service
echo "NaïveProxy 安装成功"
echo "客户端连接信息: "
echo "端口: ${naive_port}"
echo "用户名: ${naive_user}"
echo "密码: ${naive_pass}"
echo "SNI: ${naive_domain}"
