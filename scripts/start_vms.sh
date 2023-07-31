#!/bin/bash
<<comment
=============================================================================================================================
======================= This Script will Start the VMs post reboot of the Bare Metal server =================================
=============================================================================================================================
Operating System :   Oracle Linux 8
Inputs           :   -
Outputs          :   -
Execution        :   Called from Systemctl service
Example          :   -
=============================================================================================================================
comment

echo "=============================================================================="
echo "=========================== Start of VMs' start =============================="
echo "=============================================================================="

# MDEVCTL List
echo "=========================== Initial MDEVCTL List ============================="
export LC_ALL=en_US.utf8
mdevlist=`sudo mdevctl list | wc -l`
echo $mdevlist
vm_count=`sudo virsh list --inactive | grep vm | wc -l`
echo "============================= INACTIVE Domains'/VMs' Count ====================="
echo $vm_count

if sudo virsh list --inactive | grep shut; then 
  value=`sudo virsh list --inactive | grep shut | wc -l`
  while [ $value -gt 0 ]; do
    for i in $(sudo virsh list --inactive | awk '{print $2}' | grep vm); do sudo virsh start $i; done
    value=`sudo virsh list --inactive | grep shut | wc -l`
    echo "=============== Wait for the vgpu slices/devices to come up =================="
  done
  echo "============================== Final MDEVCTL List ============================"

  mdevlist=`sudo mdevctl list | wc -l`
  echo "=============================== count  $mdevlist ============================="
  sudo virsh list --all
  sudo virsh list --all
  sudo virsh list --all
fi
sudo nvidia-smi
echo "============================= End of VMs' start =============================="
echo "=============================================================================="