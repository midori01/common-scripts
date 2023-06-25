#!/bin/bash

read -p "请输入 access_token (留空将从 wgcf-account.toml 文件中获取): " access_token_input
if [ -z "$access_token_input" ]; then
  if [ -f "/etc/wireguard/wgcf-account.toml" ]; then
    access_token=$(grep -Po "(?<=access_token = ')[^']+" /etc/wireguard/wgcf-account.toml)
  else
    echo "/etc/wireguard/wgcf-account.toml 文件不存在"
    exit 1
  fi
else
  access_token="$access_token_input"
fi
if [ -n "$access_token" ]; then
  read -p "请输入 device_id (留空将从 wgcf-account.toml 文件中获取): " device_id_input
  if [ -z "$device_id_input" ]; then
    if [ -f "/etc/wireguard/wgcf-account.toml" ]; then
      device_id=$(grep -Po "(?<=device_id = ')[^']+" /etc/wireguard/wgcf-account.toml)
    else
      echo "/etc/wireguard/wgcf-account.toml 文件不存在"
      exit 1
    fi
  else
    device_id="$device_id_input"
  fi
fi
response=$(curl --request GET "https://api.cloudflareclient.com/v0a2158/reg/${device_id}" \
  --silent \
  --location \
  --header 'User-Agent: okhttp/3.12.1' \
  --header 'CF-Client-Version: a-6.10-2158' \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer ${access_token}")
client_id=$(echo "$response" | grep -Po '(?<=client_id":")[^"]+')
decoded_client_id=$(echo "$client_id" | base64 -d | xxd -p | fold -w2 | while read HEX; do printf '%d ' "0x${HEX}"; done | awk '{print "["$1", "$2", "$3"]"}')
echo "WARP Reserved: ${decoded_client_id}"