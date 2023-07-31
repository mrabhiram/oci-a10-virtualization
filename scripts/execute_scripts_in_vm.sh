#!/bin/bash
<<comment
=============================================================================================================================
======================= This Script will Copy files to the VMs from Bare Metal server and Executes Scripts on the VMs =======
=============================================================================================================================
Operating System :   Oracle Linux 8
Inputs           :   secret_ocid,experience_id
Outputs          :   -
Execution        :   ./execute_scripts_in_vm.sh <secret_ocid> <experience_id>
=============================================================================================================================
comment

echo "=============================================================================="
echo "==================== Start of Copy/Execute scripts in VMs ===================="
echo "=============================================================================="


export LC_ALL=en_US.utf8
SECRET_OCID=$1
EXPERIENCE_ID=$2

echo " Experience ID is $EXPERIENCE_ID"

# Make a directory and create a temporary private key file
sudo mkdir -p /home/opc/temp/.ssh
sudo touch /home/opc/temp/.ssh/private.pem
sudo chown opc:opc /home/opc/temp/.ssh/private.pem
oci secrets secret-bundle get --auth instance_principal --raw-output --secret-id $SECRET_OCID --query "data.\"secret-bundle-content\".content" | base64 -d >> /home/opc/temp/.ssh/private.pem
sudo chmod 400 /home/opc/temp/.ssh/private.pem

# Organize files to be copied to the VMs
sudo mkdir -p /home/opc/vm
sudo chown opc:opc /home/opc/vm
# #sudo cp -p /home/opc/vgaming/510.73.05-May2022-Cloud_Gaming-Linux-Guest-Drivers.zip /home/opc/vm/
# sudo cp -p /home/opc/vgaming/NVIDIA-Linux-x86_64-510.60.02-grid.run /home/opc/vm/
sudo cp -p /home/opc/scripts/install_packages_in_vm.sh /home/opc/vm/
sudo cp -p /home/opc/scripts/execute_scripts_post_reboot_in_vm.sh /home/opc/vm/
sudo cp -p /home/opc/scripts/check_vm_status.sh /home/opc/vm/


# Loop through the Private IPs to test connection to the VMs
LINES=$(cat /home/opc/scripts/oci-private-ips.txt)
for line in $LINES;do 
  echo "Executing command 'pwd' in $line"
    while ! execute_scripts=`ssh -o "StrictHostKeyChecking=no" -i /home/opc/temp/.ssh/private.pem ubuntu@${line} pwd`
  do
      sleep 2
      echo "Please wait!! VM takes a couple of minutes to be up and running.....Trying to connect again...."
  done
  echo $execute_scripts
done

# Loop through the Public IPs to connect to the VMs and complete the configuration
LINES=$(cat /home/opc/scripts/oci-public-ips.txt)
for line in $LINES;do 
  echo "Copy Files to $line"
  while ! copy_files=`scp -r -i /home/opc/temp/.ssh/private.pem  -o "StrictHostKeyChecking=no" /home/opc/vm ubuntu@${line}:~/`
  do
      echo "Please wait!! VM takes a couple of minutes to be up and running.....Trying to connect again...."
  done
  echo "Copy is complete............................................................"
  echo "Execute Scripts in $line"
  execute_scripts=`ssh -o "StrictHostKeyChecking=no" -i /home/opc/temp/.ssh/private.pem ubuntu@${line} ls vm/`
  echo $execute_scripts
  execute_scripts_in_vm=`ssh -o "StrictHostKeyChecking=no" -i /home/opc/temp/.ssh/private.pem ubuntu@${line}  bash /home/ubuntu/vm/install_packages_in_vm.sh $EXPERIENCE_ID`
  echo $execute_scripts_in_vm

<<comment
  # Execute commands post reboot of VM
  while ! execute_scripts_post_reboot=`ssh  -o "StrictHostKeyChecking=no" -i /home/opc/temp/.ssh/private.pem ubuntu@${line} bash /home/ubuntu/vm/execute_scripts_post_reboot_in_vm.sh`
   do
      sleep 2
      echo "Please wait!! VM takes a couple of minutes to be up and running.....Trying to connect again...."
   done
  echo $execute_scripts_post_reboot
comment

done

sudo rm -rf /home/opc/temp
sudo cat /home/opc/scripts/vm-details.txt

echo "==================== End of Copy/Execute scripts in VMs ======================"
echo "=============================================================================="