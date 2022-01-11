#!/bin/bash
# Copyright (c) 2022, Huang Daojin
# All rights reserved.
# Name: adduser.sh
# Author: Huang Daojin
# Date: 2022.01.11
Version="1.0.0"
# Description: This script is used to add user. The password of user will be changed when user first login.
# Usage: ./adduser.sh
# Apply: Debian 11

# Set some variables
unset LANG
export LANG=en_US.UTF-8

usage() {
    cat <<EOF
    Usage: $(basename $0) [OPTION]... FILE
    Add multiple users to the system.The password of user will be changed when user first login.

    -h        Display this help and exit.
    -v        Output version information and exit.
EOF
}

# Start running

if [ $# -eq 1 ]; then
    while getopts "hv" arg; do
        case $arg in
        h)
            usage
            exit 0
            ;;
        v)
            echo "$(basename $0) version: $Version"
            exit 0
            ;;
        ?)
            usage
            exit 1
            ;;
        esac
    done
    password="Skills39!"
    while read line; do
        username="$line"
        [ -z "$username" ] && continue
        grep -q "^$username:" /etc/passwd
        if [ $? -eq 0 ]; then
            echo "User $username already exists."
        else
            useradd -m -s /bin/bash $username
            echo "$username:$password" | chpasswd
            passwd -e $username
            echo "User $username has been added."
        fi
    done <$1
else
    usage
    exit 1
fi
