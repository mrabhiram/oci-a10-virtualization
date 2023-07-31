#!/bin/bash
<<comment
=============================================================================================================================
================= This Script will Enable and Start Systemctl Services for DHCP, LIBVIRTD and NVIDIA CARDs ==================
=============================================================================================================================
Operating System :   Oracle Linux 8
Inputs           :   - 
Outputs          :   -
Execution        :   nohup ./enable_disable_services.sh >> enable_disable_services.out 2>&1 &
=============================================================================================================================
comment

echo "=============================================================================="
echo "==================== Start of Enable/Disable Services ========================"
echo "=============================================================================="

# Disable SELINUX
export LC_ALL=en_US.utf8
sudo sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
sudo setenforce 0
sudo getenforce

# Enable DHCP
echo "=========================== Enable/Start DHCP ================================="
sudo systemctl enable dhcpd
sudo systemctl start dhcpd
sudo systemctl status dhcpd

# Enable and start libvirtd
echo "========================= Enable/Start Libvirt ==============================="
sudo systemctl enable libvirtd.service
sudo systemctl start libvirtd.service
sudo systemctl status libvirtd.service

# # Enable NVIDIA Cards via systemctl service
echo "===================== Enable/Start NVIDIA Cards =============================="
sudo mv /home/opc/scripts/enable_nvidia_cards.service /etc/systemd/system/enable_nvidia_cards.service
sudo chown root:root /etc/systemd/system/enable_nvidia_cards.service
sudo systemctl daemon-reload
sudo systemctl enable enable_nvidia_cards.service
sudo systemctl start enable_nvidia_cards.service
sudo systemctl status enable_nvidia_cards.service

echo "======================= End of Enable/Disable Services ======================="
echo "=============================================================================="