#!/bin/bash
# Copyright (c) 2021, Huang Daojin
# All rights reserved.
# Name: iptables-webserver.sh
# Author: Huang Daojin
# Date: 2022-01-03
# Version: 1.0.0
# Description: This script is used to set iptables rules for webserver.
# Usage: ./iptables-webserver.sh
# Apply: RHEL/CentOS/Rocky 8

# Set some variables
unset LANG
export LANG=en_US.UTF-8
ipts=/sbin/iptables
ssh_port=1019
http_port=80
https_port=443
#mod=/sbin/modprobe

# Check and install iptables-services if not exist
rpm -q iptables-services >/dev/null 2>&1
if [ $? -ne 0 ]; then
    dnf -y install iptables-services
fi

# Disable other firewall services
for service in firewalld ip6tables nftables; do
    systemctl stop $service
    systemctl disable $service
done

systemctl start iptables
systemctl enable iptables

# Flush all rules
echo "[+] Flush all rules..."
$ipts -F
$ipts -t nat -F
$ipts -X

# Set web server rules
# Drop all packets that are INVALID
echo "[+] Set web server rules..."
$ipts -A INPUT -m state --state INVALID -j DROP
$ipts -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
$ipts -A INPUT -p tcp -m multiport --dports $http_port,$https_port -m state --state NEW -j ACCEPT
$ipts -A INPUT -i lo -j ACCEPT
# Drop ssh connection if retry more than 5 times in 10 minutes
$ipts -A INPUT -p tcp --dport $ssh_port -m state --state NEW -m recent --name ssh --update --seconds 600 --hitcount 5 -j DROP
$ipts -A INPUT -p tcp --dport $ssh_port -m state --state NEW -m recent --name ssh --set -j ACCEPT
# $ipts -A INPUT -p tcp --dport $ssh_port -m state --state NEW -m recent --name ssh --set
# $ipts -A INPUT -p tcp --dport $ssh_port -m state --state NEW -j ACCEPT
# Drop all other packets
$ipts -A INPUT -j REJECT --reject-with icmp-host-prohibited
$ipts -A FORWARD -j REJECT --reject-with icmp-host-prohibited

# if you want to ping this server, you can use the following rules
# $ipts -I INPUT 3 -p icmp --icmp-type 8 -j ACCEPT

# Save rules
echo "[+] Save rules..."
service iptables save
