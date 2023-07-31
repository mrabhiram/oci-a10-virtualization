# oci-a10-virtualization
An terraform + Linux automation to virtualize A10 instance in OCI and create public VMs with vGPUs attached to it. 


# Below are the required assumptions for this terraform automation
1. OCI tenancy should be approved for Level 2 networking. This script requires VLAN. For more info: https://docs.oracle.com/en-us/iaas/Content/VMware/Tasks/ocvsmanagingl2net.htm
2. This script takes in an existing VCN which has atleast one public subnet and one private subnet. This is in the form of an terraform input variable to the script.
3. This script needs Baremetal GPU A10 in OCI. Please make sure A10 GPUs are enabled in the OCI tenancy. 
4. This script uses linux qcow2 image to provision the required VMs. For our purposes, we have used simple ubuntu 20_04 qcow2 disk image. Disk images are faster to load, that is the reason its better to use disk images so the whole automation is faster to execute.
5. This script expects an object storage bucket named "AutomationScripts" with the following items in it
   1. NVIDIA host drivers. In this script we used 510.60.02 NVIDIA drivers
   2. Linux ubuntu qcow2 image for the VMs.
   3. Linux scripts for the automation. (scripts directory attached in this repo). We make the scripts available in the object storage, so that its easier for us to tweak Linux code for future releases.

Please reach out to understand more about this 

Attached is the workflow of how the automation works. 

![vGPU Diagram](https://github.com/mrabhiram/oci-a10-virtualization/assets/1394059/f81a5511-1991-48fd-9aba-c699a205a927)


# Below are the inputs for the terraform script.
1. gbs_for_vm - The Amount of NVIDIA RAM (in GBs) to split each VM into. Each A10 has 24GB NVIDIA RAM. Accepted values (2,4,6,8,12 and 24) 
2. vlan_cidr_block - The CIDR block to create the new VLAN. Make sure this CIDR block does not overlap with any other CIDR block components in the attached OCI VCN.

```
>GPU/vgpu-terraform>terraform apply
var.gbs_for_vm
  Enter a value: 12

var.vlan_cidr_block
  Enter a value: 10.0.24.0/24
```

In the above example, 12 GB profile gives you 2 VMs per A10(24 GB). Since there are two A10 cards in this instance, there are total 4 VMs created. 


# Expected OUTPUT
```
Outputs:

VM_public_ips = [
  [
    "129.xxx.xxx.xxx",
    "193.xxx.xxx.xxx",
    "129.xxx.xxx.xxx",
    "141.xxx.xxx.xxx",
  ],
]
instance_public_ip = [
  [
    "129.xxx.xxx.xxx",
  ],
]
```
