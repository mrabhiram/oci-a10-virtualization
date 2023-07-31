#!/bin/bash
<<comment
=============================================================================================================================
================================ This Script will Install the required packages on the Bare Metal server ===================
=============================================================================================================================
Operating System :   Oracle Linux 8
Inputs           :   -
Outputs          :   Creates a directory and downloads the required Custom Image Export file for the VMs and Nvidia Driver
Execution        :   ./install_packages_in_baremetal.sh
=============================================================================================================================
comment

echo "=============================================================================="
echo "=========================== Start of Installation ============================"
echo "=============================================================================="

export LC_ALL=en_US.utf8

# Make a directory named vgaming and cd to it
sudo cd /home/opc/vgaming

# Install Packages
sudo dnf install -y libvirt
sudo dnf install -y qemu-kvm
sudo dnf install -y virt-install
sudo dnf install -y virt-viewer
#sudo dnf groupinstall -y 'Server with GUI'
sudo dnf install -y epel-release
sudo dnf install -y @virt
sudo dnf install -y virt-manager
#sudo dnf install -y tigervnc-server
sudo dnf install -y mdevctl
sudo dnf install -y dhcp-server
sudo lsmod | grep kvm

# Install OCI CLI packages
sudo dnf -y install oraclelinux-developer-release-el8
sudo dnf -y install python36-oci-cli

# Validate
virt-host-validate
echo "=========================== End of Installation =============================="
echo "=============================================================================="

echo "=======Download Custom Image Export file for the VMs and Nvidia Drivers ======"
sudo unzip /home/opc/vgaming/Gaming-KVM-Host-Drivers510.60.02-March2022-Cloud_Gaming-KVM-Host-Drivers.zip
sudo bash ./NVIDIA-Linux-x86_64-510.60.02-vgaming-vgpu-kvm.run -sq
sudo nvidia-smi
sudo chmod 777 *
sudo mv /home/opc/vgaming/scripts /home/opc

# Extend the Boot Volume at /
sudo growpart /dev/sda 3
sudo xfs_growfs /
lsblk
sudo pvresize /dev/sda3
sudo pvs
sudo vgs
sudo lvs
sudo lvextend -l +100%FREE /dev/ocivolume/root
lsblk
df -kh

echo "=========================== Bare Metal Server Reboot ======================"
# Reboot Server
sudo reboot