#!/bin/bash
<<comment
=============================================================================================================================
======================= This Script will install packages on the VMs ========================================================
=============================================================================================================================
Operating System :   Oracle Linux 8
Inputs           :   -
Outputs          :   -
Execution        :   ./install_packages_in_vm.sh 
=============================================================================================================================
comment

echo "=============================================================================="
echo "==================== Start of packages' installation in VM ==================="
echo "=============================================================================="
EXPERIENCE_ID=$1
echo " Experience ID is $EXPERIENCE_ID"
cd /home/ubuntu/vm
sudo bash NVIDIA-Linux-x86_64-510.60.02-grid.run -qs
sudo nvidia-smi
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y nvidia-docker2 -q
sudo systemctl restart docker
sudo docker run --rm --gpus all nvidia/cuda:11.0.3-base-ubuntu20.04 nvidia-smi

echo "==================== End of packages' installation in VMs ===================="
echo "=============================================================================="
