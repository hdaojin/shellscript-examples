#!/bin/bash
# 竞赛环境初始化脚本
# This script is used to initialize the environment for the competition because  there are too many machines.
# First,  write the following code in the notepad in Windows system.
# Seceond, execute `vi cinit.sh` in the terminal of Linux system that you want to initialize.
# Third, copy the code in the notepad and paste it in the terminal.
# Finally, execute `bash cinit.sh` in the terminal.
# Usage:   source   init.sh   192.168.229.101/24  192.168.229.254    server01

hip=$1
hgw=$2
hos=$3
dom=skills39.org
hdns=114.114.114.114

# configure  apt 
sed  -i  's/noauto/auto/'   /etc/fstab
mount  -a 
apt   update

# install some  software
apt   -y  install  vim   ssh  ntpdate  net-tools  bash-completion

# configure ip address
cat >> /etc/network/interfaces<<EOF
auto  ens33
iface  ens33  inet static
address  $hip
gateway  $hgw
EOF

cat   >>/etc/resolv.conf <<EOF
search  $dom
domain  $dom
nameserver   $hdns
EOF

#  hostname

hostnamectl  set-hostname  $hos

#  configure   /etc/hosts
sed  -i "s/debian/$hos.$dom    $hos/"   /etc/hosts

# bash  completion
sed  -i  '32,38s/^#//'       /etc/bash.bashrc

# restart system
reboot
