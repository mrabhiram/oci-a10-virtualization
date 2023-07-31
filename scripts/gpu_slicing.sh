#!/bin/bash
<<comment
=============================================================================================================================
======================= This Script will do the GPU Slicing based on the vGPU GBs input for the VM ==========================
=============================================================================================================================
Operating System :   Oracle Linux 8
Inputs           :   gbs_for_vm
Outputs          :   -
Execution        :   ./gpu_slicing.sh <gbs_for_vm>
Example          :   ./gpu_slicing.sh 4 
=============================================================================================================================
comment

echo "=============================================================================="
echo "=========================== Start of GPU Slicing ============================="
echo "=============================================================================="

export LC_ALL=en_US.utf8

# Input Arguments
gbs_for_vm=$1

# Enable the GPU cards on Bare Metal server
sudo /usr/lib/nvidia/sriov-manage -e 00000000:17:00.0
sudo /usr/lib/nvidia/sriov-manage -e 00000000:31:00.0

# Slicing the GPU
echo "Begin GPU Slicing ................................................................"
connection_bus_list=`ls /sys/class/mdev_bus`
cbus_counter=0
profile_counter=0
echo "=============================================================================="
echo "=================== Available Devices Before GPU Slicing ====================="
for cbus in $connection_bus_list; do
  cbus_dir=${cbus//:/\\:} 
  cbus=${cbus//:/\\:} | tr -d '\r'
  profile_name=`cd /sys/class/mdev_bus/${cbus}/mdev_supported_types/ && grep -l "A10-${gbs_for_vm}" nvidia-*/name`  
  profile_name=`echo ${profile_name///name/} | tr -d '\r'`
  cbus_counter=$(($cbus_counter+1))
  for profile in $profile_name; do
    available_instances=`cat /sys/class/mdev_bus/${cbus}/mdev_supported_types/${profile}/available_instances`

    echo "Available Instances = $available_instances"
    echo "gbs_for_vm = $gbs_for_vm"
    echo "Profiles = $profile"
    echo "=============================================================================="
    if [ $available_instances -eq 1 ]
    then
      echo "`uuidgen`" | sudo tee /sys/class/mdev_bus/${cbus}/mdev_supported_types/${profile}/create
      sudo mdevctl define --auto --uuid `ls /sys/class/mdev_bus/${cbus}/mdev_supported_types/${profile}/devices`
      echo ${cbus_dir} ${available_instances}
    fi
    profile_counter=$(($profile_counter+1))
  done;
  echo "Profile Count = $profile_counter"
done;
echo "CBUS Count = $cbus_counter"
vgpu_slices_created=`sudo mdevctl list | wc -l`
vgpu_slices_created=$(($vgpu_slices_created-1))
echo "=============================================================================="
echo "MDEVCTL LIST"
echo "=============================================================================="

sudo mdevctl list
echo "VGPU Slices Created = $vgpu_slices_created"

echo "=========================== End of GPU Slicing ==============================="
echo "=============================================================================="

