#!/bin/bash

Green="\033[36m"
Font="\033[0m"
Red="\033[31m" 
root_need(){
    if [[ $EUID -ne 0 ]]; then
        echo -e "${Red}错误:此脚本必须以根目录运行!${Font}"
        exit 1
    fi
}
ovz_no(){
    if [[ -d "/proc/vz" ]]; then
        echo -e "${Red}错误:您的VPS基于OpenVZ,不支持!${Font}"
        exit 1
    fi
}
add_swap(){
echo -e "${Green}请输入需要添加的swap(建议为内存的1.5-2倍)${Font}"
read -p "请输入swap数值(单位M):" swapsize
grep -q "swap" /etc/fstab
if [ $? -ne 0 ]; then
	echo -e "${Green}swap未发现，正在为其创建swap${Font}"
	fallocate -l ${swapsize}M /swap
	chmod 600 /swap
	mkswap /swap
	swapon /swap
	echo '/swap none swap defaults 0 0' >> /etc/fstab
         echo -e "${Green}swap创建成功，并查看信息：${Font}"
         cat /proc/swaps
         cat /proc/meminfo | grep Swap
else
	echo -e "${Red}swap已存在，swap设置失败，请先运行脚本删除swap后重新设置！${Font}"
fi
}
del_swap(){
grep -q "swap" /etc/fstab
if [ $? -eq 0 ]; then
	echo -e "${Green}swap已发现，正在将其移除...${Font}"
	sed -i '/swap/d' /etc/fstab
	echo "3" > /proc/sys/vm/drop_caches
	swapoff -a
	rm -f /swap
    echo -e "${Green}swap已删除！${Font}"
else
	echo -e "${Red}swapfile未发现，swap删除失败！${Font}"
fi
}
main(){
root_need
ovz_no
clear
echo -e "———————————————————————————————————————"
echo -e "${Green}Linux VPS一键添加/删除swap脚本${Font}"
echo -e "${Green}1、添加swap${Font}"
echo -e "${Green}2、删除swap${Font}"
echo -e "———————————————————————————————————————"
read -p "请输入数字 [1-2]:" num
case "$num" in
    1)
    add_swap
    ;;
    2)
    del_swap
    ;;
    *)
    clear
    echo -e "${Green}请输入正确数字 [1-2]${Font}"
    sleep 2s
    main
    ;;
    esac
}
main
