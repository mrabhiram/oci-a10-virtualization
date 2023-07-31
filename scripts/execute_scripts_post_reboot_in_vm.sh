#!/bin/bash
<<comment
=============================================================================================================================
======================= This Script Execute Scripts on the VMs post reboot ==================================================
=============================================================================================================================
Operating System :   Oracle Linux 8
Inputs           :   -
Outputs          :   -
Execution        :   ./execute_scripts_post_reboot_in_vm.sh
=============================================================================================================================
comment

echo "=============================================================================="
echo "================== Start of Execute scripts in VMs post reboot ==============="
echo "=============================================================================="

cd /home/ubuntu/vm
while ! execute_docker_status=`sudo docker run --rm --gpus all nvidia/cuda:11.0.3-base-ubuntu20.04 nvidia-smi`
do
    sleep 2
    echo "Please wait for the docker container to be up..."
done
echo $execute_docker_status

echo "================== End of Execute scripts in VMs post reboot ==============="
echo "============================================================================"