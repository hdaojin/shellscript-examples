#!/bin/bash
# This script is used to initialize the ansible controller(Debian) environment.
# It is used to install the necessary software and set the necessary configuration.
# Author: hdaojin
# Date: 2024-10-23
# Version: 1.0
# Usage: source init-ansible-controller.sh

# Check the root permission
echo "Checking the root permission..."
if [ $UID -ne 0 ]; then
    echo "You must be root to run this script."
    exit 1
fi

# Check the Debian system and version
echo "Checking the Debian system and version..."
grep -q '^12' /etc/debian_version
if [ $? -ne 0 ]; then
    echo "This script is only for Debian 12."
    exit 2
fi

# Configure apt source using the Tsinghua mirror, you can modify it according to your needs.
replace_apt_source(){
    echo "Configuring the apt source using the Tsinghua mirror..."
    apt install -y apt-transport-https ca-certificates

    cat > /etc/apt/sources.list <<EOF
    deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free non-free-firmware
    # deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free non-free-firmware

    deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware
    # deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware

    deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware
    # deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware

    deb https://mirrors.tuna.tsinghua.edu.cn/debian-security bookworm-security main contrib non-free non-free-firmware
    # deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security bookworm-security main contrib non-free non-free-firmware
EOF
    # Update the apt source
    echo "Updating the apt source..."
    apt update
}


upgrade_system(){
    # Upgrade the system
    echo "Upgrading the system..."
    apt upgrade -y
}

install_necessary_software(){
    # Install the necessary software
    echo "Installing the necessary software..."
    apt install -y 
        dbus \
        vim \
        ssh \
        bash-completion \
        sudo \
        python3 \

    # Auto remove the unnecessary software
    echo "Auto removing the unnecessary software..."
    apt autoremove -y

    # Start the dbus service
    echo "Starting the dbus service..."
    systemctl enable --now dbus
}

install_necessary_software_for_ansible(){
    # Install the necessary software
    echo "Installing the necessary software for ansible controller..."
    apt install -y
        python3-passlib \
        ansible \
        curl \
        wget \
        sshpass \
        git

    # Auto remove the unnecessary software
    echo "Auto removing the unnecessary software..."
    apt autoremove -y
}


set_base_config(){
    # Set the hostname
    echo "Setting the hostname..."
    read -p "Please enter the hostname: " host_name
    hostnamectl set-hostname $host_name

    # Set the hosts file
    echo "Setting the hosts file..."
    sed -i "s/^127.0.1.1.*$/127.0.1.1\t$host_name/" /etc/hosts

    # Set the timezone to Asia/Shanghai
    echo "Setting the timezone to Asia/Shanghai..."
    timedatectl set-timezone Asia/Shanghai

    # set the locale to zh_CN.UTF-8, set the language to zh_CN:zh
    # sed -i 's/^# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen
    # locale-gen
    # update-locale LANG=zh_CN.UTF-8
    echo "Setting the locale to zh_CN.UTF-8 and the language to zh_CN:zh..."
    localectl set-locale LANG=zh_CN.UTF-8 LANGUAGE=zh_CN:zh

    # Set the sshd configuration "UseDNS no"
    echo "Setting the sshd configuration 'UseDNS no'..."
    sed -i 's/^#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config

    # Restart the sshd service
    echo "Restarting the sshd service..."
    systemctl restart sshd
}


configure_sudoers(){
    # Set normal user with sudo permission
    read -p "Please enter the username: " user_name
    echo "Setting the normal user with sudo permission..."
    id $user_name &> /dev/null
    if [ $? -ne 0 ]; then
        useradd -m -s /bin/bash $user_name
        passwd $user_name
    fi

    grep -q "^${user_name}" /etc/sudoers
    # Set the sudo permission without password for the normal user
    echo "${user_name} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$user_name
}


# Select the network interface
select_interface(){
    echo "Selecting the network interface..."
    # Get all the network interfaces except lo and select one of them
    select interface in $(ls /sys/class/net | grep -v "lo"); do
        if [ -n "$interface" ]; then
            echo "You have selected the network interface $interface."
            break
        else
            echo "Please select the network interface."
        fi
    done
}


# Check the network interface has a dynamic IP address
check_dynamic_ip(){
    echo "Checking the network interface has a dynamic IP address..."
    current_ip=$(ip -4 addr show $interface |grep "inet" |awk '{print $2}')
    current_gw=$(ip -4 route | grep default | awk '{print $3}')
    current_dns=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'|head -1)
    if [ -n "$current_ip" ]; then
        echo "The network interface $interface has a dynamic IP address $current_ip."
        echo "The gateway is $current_gw."
        echo "The nameserver is $current_dns."
        return 0
    else
        return 1
    fi
}


# Use the dynamic IP address as the static IP address
set_static_ip(){
    echo "Using the dynamic IP address as the static IP address..."
    interface=$1
    ip_address=$2
    gateway=$3
    dns=$4

    cp  /etc/network/interfaces /etc/network/interfaces.bak
    echo "source /etc/network/interfaces.d/*" > /etc/network/interfaces
    echo "auto lo" >> /etc/network/interfaces
    echo "iface lo inet loopback" >> /etc/network/interfaces

    if [ -n "$ip_address" ]; then
        ip_part=$(echo $ip_address | cut -d '/' -f 1)
        prefix_part=$(echo $ip_address | cut -d '/' -f 2)
        echo "" >> /etc/network/interfaces
        echo "auto ${interface}" >> /etc/network/interfaces
        echo "iface ${interface} inet static" >> /etc/network/interfaces
        echo -e "\taddress ${ip_part}/${prefix_part}" >> /etc/network/interfaces
        if [ -n "$gateway" ]; then
            echo -e "\tgateway ${gateway}" >> /etc/network/interfaces
        fi
        if [ -n "$dns" ]; then
            sed -i "s/^nameserver.*$/nameserver   ${dns}/" /etc/resolv.conf
        fi
    else
        echo "The IP address is empty."
        exit 1
    fi
}


# manuall set the static IP address
manual_set_static_ip(){
    echo "Manually setting the static IP address..."
    read -p "Please enter the static IP address(eg: 192.168.190.100/24): " ip_address
    read -p "Please enter the gateway: " gateway
    read -p "Please enter the nameserver: " dns
    set_static_ip $interface $ip_address $gateway $dns
}


restart_network_service(){
    # Restart the network service
    echo "Restarting the network service..."
    systemctl restart networking
}


#configure networking
configure_network(){
    echo "Configuring the network interface..."
    select_interface

    if check_dynamic_ip; then
        read -p "Do you want to use the dynamic IP address as the static IP address? [y/n] " choice
        if [ $choice == "y" -o $choice == "Y" ]; then
            set_static_ip $interface $current_ip $current_gw $current_dns
            restart_network_service
        else
            read -p "Do you want to manually set the static IP address? [y/n] " choice
            if [ $choice == "y" -o $choice == "Y" ]; then
                manual_set_static_ip
                restart_network_service
            else
                echo "You have not set the static IP address."
            fi
        fi
    else
        read -p "Do you want to manually set the static IP address? [y/n] " choice
        if [ $choice == "y" -o $choice == "Y" ]; then
            manual_set_static_ip
            restart_network_service
        else
            echo "You have not set the static IP address."
        fi
    fi
}

# main
read -p "Do you want to configure the network? [y/n] " choice
if [ $choice == "y" -o $choice == "Y" ]; then
    configure_network
fi

read -p "Do you want to install the necessary software, such as dbus, vim, ssh, bash-completion, sudo, python3? [y/n] " choice
if [ $choice == "y" -o $choice == "Y" ]; then
    install_necessary_software
fi

read -p "Do you want to set the base configuration? [y/n] " choice
if [ $choice == "y" -o $choice == "Y" ]; then
    set_base_config
fi

read -p "Do you want to configure the sudoers? [y/n] " choice
if [ $choice == "y" -o $choice == "Y" ]; then
    configure_sudoers
fi

read -p "Do you want to replace the apt source using the Tsinghua mirror? [y/n] " choice
if [ $choice == "y" -o $choice == "Y" ]; then
    replace_apt_source
fi

read -p "Do you want to upgrade the system? [y/n] " choice
if [ $choice == "y" -o $choice == "Y" ]; then
    upgrade_system
fi
 
read -p "Do you want to install the necessary software for ansible controller, such as python3-passlib, ansible, curl, wget, sshpass, git? [y/n] " choice
if [ $choice == "y" -o $choice == "Y" ]; then
    install_necessary_software_for_ansible
fi

read -p "Do you want to restart the system? [y/n] " choice
if [ $choice == "y" -o $choice == "Y" ]; then
    reboot
fi