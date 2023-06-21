#!/bin/bash

read -p "Cloudflare Email: " auth_email
read -p "Cloudflare API Key: " auth_key
read -p "Zone name: " zone_name
read -p "Record name: " record_name

ip_v4=$(curl -s ip.sb -4)
ip_v6=$(curl -s ip.sb -6)
ip_file="ip.txt"
id_file="cloudflare.ids"
log_file="cloudflare.log"

log() {
    if [ "$1" ]; then
        echo -e "[$(date)] - $1" >> $log_file
    fi
}

log "Check Initiated"

if [ -f $ip_file ]; then
    old_ip_v4=$(awk 'NR==1{print $1}' $ip_file)
    old_ip_v6=$(awk 'NR==2{print $1}' $ip_file)

    if [ "$ip_v4" == "$old_ip_v4" ] && [ "$ip_v6" == "$old_ip_v6" ]; then
        echo "IPs have not changed."
        exit 0
    fi
fi

if [ -f $id_file ] && [ $(wc -l $id_file | awk '{print $1}') == 4 ]; then
    zone_identifier_v4=$(awk 'NR==1{print $1}' $id_file)
    record_identifier_v4=$(awk 'NR==2{print $1}' $id_file)
    zone_identifier_v6=$(awk 'NR==3{print $1}' $id_file)
    record_identifier_v6=$(awk 'NR==4{print $1}' $id_file)
else
    zone_identifier_v4=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone_name" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1 )
    zone_identifier_v6=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone_name" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | tail -1 )

    record_identifier_v4=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier_v4/dns_records?name=$record_name" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*')
    record_identifier_v6=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier_v6/dns_records?name=$record_name" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*')

    echo "$zone_identifier_v4" > $id_file
    echo "$record_identifier_v4" >> $id_file
    echo "$zone_identifier_v6" >> $id_file

    update_v4=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier_v4/dns_records/$record_identifier_v4" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" --data "{\"id\":\"$zone_identifier_v4\",\"type\":\"A\",\"name\":\"$record_name\",\"content\":\"$ip_v4\"}")
    update_v6=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier_v6/dns_records/$record_identifier_v6" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" --data "{\"id\":\"$zone_identifier_v6\",\"type\":\"AAAA\",\"name\":\"$record_name\",\"content\":\"$ip_v6\"}")

if [[ $update_v4 == *"\"success\":false"* ]] || [[ $update_v6 == *"\"success\":false"* ]]; then
    message="API UPDATE FAILED. DUMPING RESULTS:\n"
    if [[ $update_v4 == *"\"success\":false"* ]]; then
        message+="IPv4 update failed:\n$update_v4\n"
    fi
    if [[ $update_v6 == *"\"success\":false"* ]]; then
        message+="IPv6 update failed:\n$update_v6"
    fi
    log "$message"
    echo -e "$message"
    exit 1 
else
    message="IPs changed to:\nIPv4: $ip_v4\nIPv6: $ip_v6"
    echo -e "$ip_v4\n$ip_v6" > $ip_file
    log "$message"
    echo "$message"
fi
