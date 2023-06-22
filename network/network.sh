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
ulimit() {
echo "1000000" > /proc/sys/fs/file-max
sed -i '/fs.file-max/d' /etc/sysctl.conf
cat >> '/etc/sysctl.conf' << EOF
fs.file-max=1000000
EOF
ulimit -SHn 1000000 && ulimit -c unlimited
echo "root     soft   nofile    1000000
root     hard   nofile    1000000
root     soft   nproc     1000000
root     hard   nproc     1000000
root     soft   core      1000000
root     hard   core      1000000
root     hard   memlock   unlimited
root     soft   memlock   unlimited

*     soft   nofile    1000000
*     hard   nofile    1000000
*     soft   nproc     1000000
*     hard   nproc     1000000
*     soft   core      1000000
*     hard   core      1000000
*     hard   memlock   unlimited
*     soft   memlock   unlimited
">/etc/security/limits.conf
if grep -q "ulimit" /etc/profile; then
  :
else
  sed -i '/ulimit -SHn/d' /etc/profile
  echo "ulimit -SHn 1000000" >>/etc/profile
fi
if grep -q "pam_limits.so" /etc/pam.d/common-session; then
  :
else
  sed -i '/required pam_limits.so/d' /etc/pam.d/common-session
  echo "session required pam_limits.so" >>/etc/pam.d/common-session
fi
sed -i '/DefaultTimeoutStartSec/d' /etc/systemd/system.conf
sed -i '/DefaultTimeoutStopSec/d' /etc/systemd/system.conf
sed -i '/DefaultRestartSec/d' /etc/systemd/system.conf
sed -i '/DefaultLimitCORE/d' /etc/systemd/system.conf
sed -i '/DefaultLimitNOFILE/d' /etc/systemd/system.conf
sed -i '/DefaultLimitNPROC/d' /etc/systemd/system.conf
cat >>'/etc/systemd/system.conf' <<EOF
[Manager]
#DefaultTimeoutStartSec=90s
DefaultTimeoutStopSec=30s
#DefaultRestartSec=100ms
DefaultLimitCORE=infinity
DefaultLimitNOFILE=65535
DefaultLimitNPROC=65535
EOF
systemctl daemon-reload
echo "ulimit 已调整"
}
dns() {
  systemctl disable --now systemd-resolved.service
  systemctl disable --now resolvconf.service
  systemctl disable --now openresolv.service
  systemctl disable --now rdnssd.service
  rm -rf /etc/resolv*
  echo -e "nameserver 1.1.1.1\nnameserver 1.0.0.1" > /etc/resolv.conf
  echo "DNS 已更换"
}
besttrace() {
  if ! command -v wget &> /dev/null; then
    echo "wget 未安装，请安装后再运行脚本"
    exit 1
  fi
  if ! command -v unzip &> /dev/null; then
    echo "unzip 未安装，请安装后再运行脚本"
    exit 1
  fi
  wget https://cdn.ipip.net/17mon/besttrace4linux.zip
  unzip besttrace4linux.zip -d best
  chmod +x best/besttrace*
  arch=$(uname -m)
  if [[ "$arch" == "x86_64" ]]; then
    mv best/besttrace /usr/bin/besttrace
  elif [[ "$arch" == "aarch64" ]]; then
    mv best/besttracearm /usr/bin/besttrace
  else
    echo "$arch 架构不支持"
    exit 1
  fi
  rm -r best besttrace4linux.zip
  echo "BestTrace 已安装"
}
tcping() {
  apt update
  apt install -y python3 python3-pip
  pip3 install tcping
  echo "tcping 已安装"
}
speedtest() {
  curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash
  apt install -y speedtest
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
if [[ $1 == "ulimit" ]]; then
  ulimit
  exit 0
fi
if [[ $1 == "dns" ]]; then
  dns
  exit 0
fi
if [[ $1 == "besttrace" ]]; then
  besttrace
  exit 0
fi
if [[ $1 == "tcping" ]]; then
  tcping
  exit 0
fi
if [[ $1 == "speedtest" ]]; then
  speedtest
  exit 0
fi
