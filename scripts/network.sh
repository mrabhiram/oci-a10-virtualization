#!/bin/bash
<<comment
=============================================================================================================================
================================= This Script will do the Network Setup for the VMs =========================================
=============================================================================================================================
Operating System :   Oracle Linux 8
Inputs           :   gbs_for_vm
Outputs          :   Generates files - oci-public-ips.txt and oci-private-ips.txt
Execution        :   ./network.sh <gbs_for_vm> "<vlan_tag>" <vlan_ocid> <vlan_cidr>
Example          :   ./network.sh 4 "100" ocid1.vlan.oc1.iad.amaaaaaantxkdlyasj7hrqdltvarji2kt3p7sq233gah7g4kk7nqzz4kek6a 10.0.30.0/24
=============================================================================================================================
comment

echo "=============================================================================="
echo "=========================== Start of Network ================================="
echo "=============================================================================="

export LC_ALL=en_US.utf8


# Arguments to accept
gbs_for_vm=$1
vlan_tag=$2
vlan_ocid=$3
vlan_cidr=$4

# Write the private IPs to txt file
sudo touch /home/opc/scripts/oci-private-ips.txt
sudo chmod 777 /home/opc/scripts/oci-private-ips.txt
oci network private-ip list --vlan-id "${vlan_ocid}" --auth instance_principal  | grep "ip-address" | awk '{print $2}' | tr -d '",' >> /home/opc/scripts/oci-private-ips.txt
sudo cat /home/opc/scripts/oci-private-ips.txt

# Write the public IPs to txt file
oci network private-ip list --vlan-id "${vlan_ocid}" --auth instance_principal  | grep "\"id\"" | awk '{print $2}' | tr -d '",' >> /home/opc/scripts/oci-private-ip-ids.txt
sudo cat /home/opc/scripts/oci-private-ip-ids.txt | while read line
do 
  oci network public-ip get  --auth instance_principal --private-ip-id  "${line}" | grep 'ip-address' | awk '{print $2}' | tr -d '",' >> /home/opc/scripts/oci-public-ips.txt
done 
sudo cat /home/opc/scripts/oci-public-ips.txt

# Create Bridge Network
sudo touch /etc/sysconfig/network-scripts/ifcfg-bridge1
sudo chown opc:opc /etc/sysconfig/network-scripts/ifcfg-bridge1
prefix=`echo ${vlan_cidr} | cut -d'/' -f2 `
gateway_ip=`./ip-addresses.sh ${vlan_cidr} | sed -n '2 p'`
ipaddress=`./ip-addresses.sh ${vlan_cidr} | sed -n '3 p'`

sudo cat <<EOT>> /etc/sysconfig/network-scripts/ifcfg-bridge1
STP=no
TYPE=Bridge
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
IPADDR=${ipaddress}
PREFIX=${prefix}
GATEWAY=${gateway_ip}
IPV4_FAILURE_FATAL=no
NAME=bridge1
UUID=
DEVICE=bridge1
ONBOOT=yes
AUTOCONNECT_SLAVES=yes
EOT
sudo chown root:root /etc/sysconfig/network-scripts/ifcfg-bridge1

for tag in ${vlan_tag}; do
  sudo touch /etc/sysconfig/network-scripts/ifcfg-ens300f0.${tag}
  sudo chown opc:opc /etc/sysconfig/network-scripts/ifcfg-ens300f0.${tag}
  network=`./ip-addresses.sh ${vlan_cidr} | sed -n '1 p'`
  sudo cat <<EOT>> /etc/sysconfig/network-scripts/ifcfg-ens300f0.${tag}
VLAN=yes
TYPE=Vlan
PHYSDEV=ens300f0
VLAN_ID=${tag}
REORDER_HDR=yes
GVRP=no
MVRP=no
HWADDR=
NAME=ens300f0.${tag}
UUID=
DEVICE=ens300f0.${tag}
ONBOOT=yes
BRIDGE=bridge1
NETWORK=${network}
EOT
  sudo chown root:root /etc/sysconfig/network-scripts/ifcfg-ens300f0.${tag}
done;

sudo ifdown bridge1
sudo ifup bridge1
for tag in ${vlan_tag}; do
  sudo ifdown ens300f0.${tag}
  sudo ifup ens300f0.${tag}
done;
sudo systemctl restart network
sudo ip a
sudo ip link show


# DHCP Configuration
dhcp_min=`./ip-addresses.sh ${vlan_cidr} | sed -n '202 p'`
dhcp_max=`./ip-addresses.sh ${vlan_cidr} | sed -n '220 p'`
router_ip=`./ip-addresses.sh ${vlan_cidr} | sed -n '2 p'`
network=`./ip-addresses.sh ${vlan_cidr} | sed -n '1 p'`
sudo touch /home/opc/scripts/dhcpd.conf
sudo chmod 777 /home/opc/scripts/dhcpd.conf
sudo cat <<EOT>> /home/opc/scripts/dhcpd.conf
# dhcpd.conf
#
# Sample configuration file for ISC dhcpd
#

# option definitions common to all supported networks...
option domain-name "vms.local";
option domain-name-servers 8.8.8.8;

default-lease-time 600;
max-lease-time 7200;

# Use this to enble / disable dynamic dns updates globally.
#ddns-update-style none;

# If this DHCP server is the official DHCP server for the local
# network, the authoritative directive should be uncommented.
#authoritative;

# Use this to send dhcp log messages to a different log file (you also
# have to hack syslog.conf to complete the redirection).
log-facility local7;

subnet ${network} netmask 255.255.255.0 {
  range ${dhcp_min} ${dhcp_max};
  option domain-name-servers 8.8.8.8;
  option domain-name "vms.local";
  option routers ${router_ip};
  default-lease-time 600;
  max-lease-time 7200;
}
EOT
sudo cp -rpf /home/opc/scripts/dhcpd.conf /etc/dhcp/dhcpd.conf 
sudo chown root:root /etc/dhcp/dhcpd.conf


# Firwall rules to open for the VMs
sudo firewall-cmd --permanent --zone=public --add-port=5900/tcp
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
sudo ip a

echo "=========================== End of Network ==================================="
echo "=============================================================================="
