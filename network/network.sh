#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "请切换到 root 用户后再运行脚本"
  exit 1
fi

bbr() {
  echo net.core.default_qdisc=fq >> /etc/sysctl.conf
  echo net.ipv4.tcp_congestion_control=bbr >> /etc/sysctl.conf
  sysctl -p
  echo "BBR 已开启"
}

tfo() {
  echo 3 > /proc/sys/net/ipv4/tcp_fastopen
  echo net.ipv4.tcp_fastopen=3 >> /etc/sysctl.conf
  sysctl -p
  echo "TCP Fast Open 已开启"
}

ipv4fwd() {
  echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf
  sysctl -p
  echo "IPv4 Forward 已开启"
}

ipv6fwd() {
  echo net.ipv6.conf.all.forwarding=1 >> /etc/sysctl.conf
  sysctl -p
  echo "IPv6 Forward 已开启"
}

network() {
sed -i '/net.ipv4.tcp_no_metrics_save/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_frto/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_mtu_probing/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_rfc1337/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_sack/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_fack/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_window_scaling/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_adv_win_scale/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_moderate_rcvbuf/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_rmem/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_wmem/d' /etc/sysctl.conf
sed -i '/net.core.rmem_max/d' /etc/sysctl.conf
sed -i '/net.core.wmem_max/d' /etc/sysctl.conf
sed -i '/net.ipv4.udp_rmem_min/d' /etc/sysctl.conf
sed -i '/net.ipv4.udp_wmem_min/d' /etc/sysctl.conf
cat >> /etc/sysctl.conf << EOF
net.ipv4.tcp_no_metrics_save=1
net.ipv4.tcp_ecn=0
net.ipv4.tcp_frto=0
net.ipv4.tcp_mtu_probing=0
net.ipv4.tcp_rfc1337=0
net.ipv4.tcp_sack=1
net.ipv4.tcp_fack=1
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_adv_win_scale=1
net.ipv4.tcp_moderate_rcvbuf=1
net.core.rmem_max=33554432
net.core.wmem_max=33554432
net.ipv4.tcp_rmem=4096 87380 33554432
net.ipv4.tcp_wmem=4096 16384 33554432
net.ipv4.udp_rmem_min=8192
net.ipv4.udp_wmem_min=8192
EOF
sysctl -p && sysctl --system
echo "内核参数已调整"
}

if [[ $1 == "bbr" ]]; then
  bbr
  exit 0
fi

if [[ $1 == "tfo" ]]; then
  tfo
  exit 0
fi

if [[ $1 == "ipv4fwd" ]]; then
  ipv4fwd
  exit 0
fi

if [[ $1 == "ipv6fwd" ]]; then
  ipv6fwd
  exit 0
fi

if [[ $1 == "network" ]]; then
  network
  exit 0
fi
