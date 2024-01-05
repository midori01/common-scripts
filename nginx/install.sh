#!/bin/bash

curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
gpg --dry-run --quiet --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/mainline/debian $(cat /etc/os-release | grep VERSION_CODENAME | cut -d'=' -f2) nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
apt update
apt install nginx -y
apt install nginx-module-njs -y
rm /etc/nginx/conf.d/*
cat > /etc/nginx/http_server_name.js <<'EOF'
var server_name = '-';

/**
 * Read the server name from the HTTP stream.
 *
 * @param s
 *   Stream.
 */
function read_server_name(s) {
  s.on('upload', function (data, flags) {
    if (data.length || flags.last) {
      s.done();
    }

    // If we can find the Host header.
    var n = data.indexOf('\r\nHost: ');
    if (n != -1) {
      // Determine the start of the Host header value and of the next header.
      var start_host = n + 8;
      var next_header = data.indexOf('\r\n', start_host);

      // Extract the Host header value.
      server_name = data.substr(start_host, next_header - start_host);

      // Remove the port if given.
      var port_start = server_name.indexOf(':');
      if (port_start != -1) {
        server_name = server_name.substr(0, port_start);
      }
    }
  });
}

function get_server_name(s) {
  return server_name;
}

export default {read_server_name, get_server_name}
EOF
cat > /etc/nginx/nginx.conf <<'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
error_log /var/log/nginx/error.log;
load_module modules/ngx_stream_js_module.so;

events {
    worker_connections 1024;
}

stream {
    map $ssl_preread_server_name $upstream_443 {
        sni.nmsl.wsnd 127.0.0.1:8443;
    }

    js_import main from http_server_name.js;
    js_set $preread_server_name main.get_server_name;

    map $preread_server_name $upstream_80 {
        host.nmsl.wsnd 127.0.0.1:8080;
    }

    server {
        listen [::]:443 ipv6only=off;
        ssl_preread on;
        proxy_pass $upstream_443;
    }

    server {
        listen [::]:80 ipv6only=off;
        js_preread main.read_server_name;
        proxy_pass $upstream_80;
    }
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    gzip on;
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    include /etc/nginx/conf.d/*.conf;
}
EOF
systemctl restart nginx.service
