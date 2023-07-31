#!/bin/bash
<<comment
=============================================================================================================================
==========This Script will Enable and Start the service (to start the VMs upon Bare Metal server reboot)=====================
=============================================================================================================================
Operating System :   Oracle Linux 8
Inputs           :   - 
Outputs          :   -
Execution        :   nohup ./enable_start_vms_services.sh >> enable_start_vms_services.out 2>&1 &
=============================================================================================================================
comment

echo "=============================================================================="
echo "== Enable/Start the service ( to start the VMs on Bare Metal server reboot ==="
echo "=============================================================================="

# # Enable vm start(via systemctl service) upon Bare Metal server reboot 
export LC_ALL=en_US.utf8
sudo cp /home/opc/scripts/start_vms.service /etc/systemd/system/start_vms.service
sudo chown root:root /etc/systemd/system/start_vms.service
sudo systemctl daemon-reload
sudo systemctl enable start_vms.service
sudo systemctl start start_vms.service
sudo systemctl status start_vms.service

echo "==End of Enable/Start the service ( to start the VMs on Bare Metal server reboot )=="
echo "===================================================================================="