#!/bin/bash

curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
gpg --dry-run --quiet --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/mainline/debian $(cat /etc/os-release | grep VERSION_CODENAME | cut -d'=' -f2) nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
apt update
apt install nginx -y
