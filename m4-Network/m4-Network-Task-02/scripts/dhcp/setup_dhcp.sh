#!/bin/bash

# Update and install required packages
dnf install dhcp-server -y

# Configure DHCP server
echo "Add config to /etc/dhcp/dhcpd.conf"
cat << EOF2 > /etc/dhcp/dhcpd.conf
# Global parameters
default-lease-time 600;
max-lease-time 7200;
log-facility local7;

# Subnet configurations
subnet 192.168.1.0 netmask 255.255.255.192 {
    option routers 192.168.1.1;
    option domain-search "db.local";
    range 192.168.1.10 192.168.1.62;

    # Host-specific configurations for net3
    host nat {
        hardware ethernet 08:00:27:12:34:56;
        fixed-address 192.168.1.1;
    }
    host dhcp {
        hardware ethernet 08:00:27:12:34:58;
        fixed-address 192.168.1.2;
    }
    host dns {
        hardware ethernet 08:00:27:12:34:57;
        fixed-address 192.168.1.3;
    }
    host R23 {
        hardware ethernet 08:00:27:12:34:63;
        fixed-address 192.168.1.4;
    }
    host R13 {
        hardware ethernet 08:00:27:12:34:60;
        fixed-address 192.168.1.5;
    }
    host Rdmz3 {
        hardware ethernet 08:00:27:12:34:66;
        fixed-address 192.168.1.6;
    }
    host client-net3 {
        hardware ethernet 08:00:27:12:34:59;
        fixed-address 192.168.1.7;
    }
}

subnet 192.168.2.0 netmask 255.255.255.224 {
    option routers 192.168.2.1;
    option domain-search "db.local";
    range 192.168.2.2 192.168.2.30;

    # Host-specific configurations for net2
    host client-net2 {
        hardware ethernet 08:00:27:12:34:65;
        fixed-address 192.168.2.3;
    }
}

subnet 192.168.3.0 netmask 255.255.255.248 {
    option routers 192.168.3.1;
    option domain-search "db.local";
    range 192.168.3.2 192.168.3.6;

    # Host-specific configurations for net1
    host client-net1 {
        hardware ethernet 08:00:27:12:34:62;
        fixed-address 192.168.3.3;
    }
}

subnet 192.168.4.0 netmask 255.255.255.248 {
    option routers 192.168.4.1;
    option subnet-mask 255.255.255.248;
    option domain-search "db.local";
    range 192.168.4.2 192.168.4.6;

    # Host-specific configurations for net-dmz
    host nginx-1 {
        hardware ethernet 08:00:27:12:34:68;
        fixed-address 192.168.4.3;
    }
    host nginx-2 {
        hardware ethernet 08:00:27:12:34:69;
        fixed-address 192.168.4.4;
    }
}

authoritative;
EOF2

# Configure /etc/sysconfig/dhcpd
echo 'INTERFACES="eth1";' > /etc/sysconfig/dhcpd

# Configure network interface eth1 using nmcli
nmcli con add type ethernet con-name eth1 ifname eth1 ipv4.method manual ipv4.addresses 192.168.1.2/26 ipv4.gateway 192.168.1.1 ipv4.dns 192.168.1.3 ipv4.dns-search db.local

# Bring up the eth1 connection
nmcli con up eth1

# Restart NetworkManager
systemctl restart NetworkManager.service
sleep 30

# Delete default name server 10.0.2.3 and configure DNS manually
echo "Add config dns config to /etc/resolv.conf.manually-configured"
cat << EOF4 > /etc/resolv.conf.manually-configured
# Generated by NetworkManager
search db.local
nameserver 192.168.1.3
EOF4

rm /etc/resolv.conf
ln -s /etc/resolv.conf.manually-configured /etc/resolv.conf

# Restart NetworkManager again
echo "Restarting network services"
systemctl restart NetworkManager.service
sleep 20
systemctl restart NetworkManager
sleep 20
service NetworkManager restart
sleep 20

# Enable and start DHCP service
systemctl enable dhcpd
systemctl start dhcpd

# Check the status of the DHCP service
systemctl status dhcpd

echo "DHCP setup completed!"
