#!/bin/bash
<<comment
=============================================================================================================================
======================= This Script will Create and Start the VMs in the Bare Metal server ==================================
=============================================================================================================================
Operating System :   Oracle Linux 8
Inputs           :   -
Outputs          :   -
Execution        :   ./vm_creation_in_baremetal.sh
Example          :   ./vm_creation_in_baremetal.sh
=============================================================================================================================
comment

echo "=============================================================================="
echo "=========================== Start of VMs' Creation ==========================="
echo "=============================================================================="

export LC_ALL=en_US.utf8

sleep 5
# Mount the NVME disk file system
echo "Mounting File System.........................................................."
sudo usermod -a -G libvirt $(whoami)
sudo mkfs.ext4 /dev/nvme0n1
sudo mkdir /mnt/data
sudo mount -t ext4 /dev/nvme0n1 /mnt/data
sudo chown -R opc:opc /mnt/data
nvme_uuid=`sudo blkid | grep /dev/nvme0n1 | awk '{print $2}'`
sudo cp -p /etc/fstab /etc/fstab_backup
echo "Adding the NVME file system details to /etc/fstab ............................"
sudo su -c "echo '$nvme_uuid        /mnt/data        ext4        defaults        0 0 ' >> /etc/fstab"

# Loop through the instances' count; create the respective directories and copy the Custom Image Export File to them
count=`sudo mdevctl list | wc -l`
count=$(($count-1))
totalMemoryInkB=`grep MemTotal /proc/meminfo|awk '{print$2}'`
totalMemoryInMB=`echo "scale=2;$totalMemoryInkB / 1024" | bc` # Must be in MBs as per virt-install
memory=`echo $totalMemoryInMB | cut -f1 -d"."` # Floor Operation
memory=$(($memory - 81920)) # Gives 80GB RAM to the Bare Metal server
memory=$(($memory / $count))
memory=`echo $memory | cut -f1 -d"."` 
totalCPUS=`lscpu | grep "CPU(s):" | awk '{print$2}' | sed -n 1p`
vcpus=$(($totalCPUS / $count))
vcpus=`echo $vcpus | cut -f1 -d"."`

while [ $count -gt 0 ];do

  # Copy the Custom Image Export File to the destination
  echo "Copying Custom Image Export File to destination folder for vm$count ............"
  sudo mkdir -p /disk/vm-${count}
  sudo cp -R /home/opc/vgaming/Ubuntu_20_04 /disk/vm-${count}
  sudo chmod -R 777 /disk/vm-${count}

  # Create VM and assign IP
  echo "Creating VM and assigning IP  .................................................."
  echo "Memory(MB):$memory    Count:$count    VCPUS:$vcpus    TotalCPUS:$totalCPUS    VM:vm${count}" 
  echo "================================================================================"
  sudo virt-install -n vm${count} --description "vGPU on A10" --network=bridge:bridge1 --os-type=Linux --os-variant=ubuntu20.04 --import --disk /disk/vm-${count}/Ubuntu_20_04,bus=virtio --vcpus=${vcpus} --ram=${memory} --graphics none --noautoconsole 
  sudo virsh list
  sudo virsh domiflist vm${count}
  mac_address=`sudo virsh domiflist vm${count} | awk '{print $5}' | sed -n 3p`
  vm_ip_address=`sudo cat /home/opc/scripts/oci-private-ips.txt | awk '{print $1}' | sed -n ${count}p`
  vm_public_ip_address=`sudo cat /home/opc/scripts/oci-public-ips.txt | awk '{print $1}' | sed -n ${count}p`

  # Stop the VM
  echo "Stopping the VM  ................................................................"
  sudo virsh destroy vm${count} --graceful

  # Edit DHCP Config
  echo "Editing DHCP Settings ............................................................"
  sudo cp /etc/dhcp/dhcpd.conf /home/opc/scripts/dhcpd.conf
  sudo chown opc:opc /home/opc/scripts/dhcpd.conf
  sudo chmod 777 /home/opc/scripts/dhcpd.conf
  sudo printf "\n# VMs\nhost vm${count} {\n  hardware ethernet ${mac_address};\n  fixed-address ${vm_ip_address};\n}" >> /home/opc/scripts/dhcpd.conf
  sudo cp /home/opc/scripts/dhcpd.conf /etc/dhcp/dhcpd.conf
  sudo chmod +x /etc/dhcp/dhcpd.conf

  # Add the vGPU info to the Instance/VM Domain XML
  uuid=`sudo mdevctl list | awk '{print$1}' | sed -n ${count}p`
  CONTENT="    <hostdev mode='subsystem' type='mdev' model='vfio-pci'>\n      <source>\n        <address uuid=\'${uuid}\'\/>\n      <\/source>\n    <\/hostdev>"
  sudo sed -i '/<\/devices>/i\'"$CONTENT" /etc/libvirt/qemu/vm${count}.xml
  sudo virsh define /etc/libvirt/qemu/vm${count}.xml

  # Restart DHCP
  nohup sudo systemctl restart dhcpd >> dhcp_restart.out 2>&1 &
  nohup sudo systemctl status dhcpd >> dhcp_status.out 2>&1 &

  # Sleep to make sure that the DHCP is up and running before starting the VM
  sleep 2

  # Start the VM
  echo "Starting the VM  ................................................................"
  sudo virsh start vm${count}

  echo "=========== VM/Instance Details ==============" >> /home/opc/scripts/vm-details.txt
  echo "VM Domain            : vm${count}" >> /home/opc/scripts/vm-details.txt
  echo "VM Private IP Address: ${vm_ip_address}" >> /home/opc/scripts/vm-details.txt
  echo "VM Public IP Address : ${vm_public_ip_address}" >> /home/opc/scripts/vm-details.txt
  echo "==============================================" >> /home/opc/scripts/vm-details.txt

  # Reset counters and values
  count=$(($count-1))

done;

echo "============================= End of VMs' Creation ==========================="
echo "=============================================================================="
