#!/bin/bash
<<comment
=============================================================================================================================
======================= This Script checks the VM status post BM/VM reboot ==================================================
=============================================================================================================================
Operating System :   Oracle Linux 8
Inputs           :   -
Outputs          :   -
Execution        :   ./check_vm_status.sh
=============================================================================================================================
comment

echo "=============================================================================="
echo "================== Start of Script ==========================================="
echo "=============================================================================="

echo "-----------------gcc version is ----------------------------------------------"
sudo gcc --version
echo "-----------------make version is ---------------------------------------------"
sudo make --version
echo "-----------------Nvidia GPU slice attached the VM-----------------------------"
sudo lspci|grep -i nvidia
echo "-----------------Nvidia Driver Status-----------------------------------------"
sudo nvidia-smi
echo "-----------------Docker Images------------------------------------------------"
sudo docker images
echo "-----------------Status--------------------------------------------------------"
sudo docker run --rm --gpus all nvidia/cuda:11.0.3-base-ubuntu20.04 nvidia-smi

echo "================== End of script ============================================="
echo "=============================================================================="