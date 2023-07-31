// Copyright (c) 2017, 2023, Oracle and/or its affiliates. All rights reserved.
// Licensed under the Mozilla Public License v2.0

variable "tenancy_ocid" {
  default = "ocid1.tenancy.oc1..aaaaaaaaiyavtwbz4kyu7g7b6wglllccbflmjx2lzk5nwpbme44mv54xu7dq"
}

variable "user_ocid" {
  default = "ocid1.user.oc1..aaaaaaaasg3uww6vbgiolhdwcpawog57ibcxfu5dzyxpdtokw35gjqywt3eq"
}

variable "fingerprint" {
  default = "1c:17:13:90:7c:f0:ef:d5:52:01:c7:80:f6:84:ce:72"
}

variable "private_key_path" {
  default = "/Users/aampabat/.oci/oci_api_key.pem"
}

variable "region" {
  default = "us-ashburn-1"
}

variable "compartment_ocid" {
  default = "ocid1.compartment.oc1..aaaaaaaaei5gupk2wigahybktwh5tlcjq7z3vwxybooe222l5atv3p25o7za"
}

variable "ssh_public_key" {
 default = "/Users/aampabat/Documents/OCI Deck/SSH/ssh-key-a10.pub"
}

variable "ssh_private_key" {
 default = "/Users/aampabat/Documents/OCI Deck/SSH/ssh-key-a10.key"
}



provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# Defines the number of instances to deploy
variable "num_instances" {
  default = "1"
}

variable "instance_shape" {
  default = "BM.GPU.T1.2"
}

variable "availability_domain" {
  default = "0"
}

variable "subnet_id" {
  default = "ocid1.subnet.oc1.iad.aaaaaaaavmbfmuxw37alwaeax37urat47ki3woiev5424qmgbr6m6tqzxr3a"
}

variable "vcn_id" {
  default = "ocid1.vcn.oc1.iad.amaaaaaawe6j4fqam5wc5op6n6xgpqjzghezl6osbnzxm2wxe3crtzuwq35a"
}

variable "vlan_cidr_block" {}

variable "gbs_for_vm" {}

variable "vlan_display_name" {
  default = "vlan-vGPU"
}

variable "vlan_nsg_ids" {
  type = list(string)
  default = ["ocid1.networksecuritygroup.oc1.iad.aaaaaaaa6uj4wkjlbz2ztmbbbahylbume2lpscjgrjl7js757774cpqm44lq"]
}


variable "instance_image_ocid" {
  type = map(string)
  default = {
    us-phoenix-1 = "ocid1.image.oc1.phx.aaaaaaaa6hooptnlbfwr5lwemqjbu3uqidntrlhnt45yihfj222zahe7p3wq"
    us-ashburn-1 = "ocid1.image.oc1.iad.aaaaaaaapcf3o54qeigj22nowwdtceyepisigpz3fho67l3xm7lmqkrgb62q"
    eu-frankfurt-1 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaadvi77prh3vjijhwe5xbd6kjg3n5ndxjcpod6om6qaiqeu3csof7a"
    uk-london-1 = "ocid1.image.oc1.uk-london-1.aaaaaaaaw5gvriwzjhzt2tnylrfnpanz5ndztyrv3zpwhlzxdbkqsjfkwxaq"
  }
}


resource "oci_core_instance" "test_instance" {
  count               = var.num_instances
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  display_name        = "vGPUA10${count.index}"
  shape               = var.instance_shape

  create_vnic_details {
    subnet_id                 = var.subnet_id
    display_name              = "Primaryvnic"
    assign_public_ip          = true
    assign_private_dns_record = true
    hostname_label            = "exampleinstance${count.index}"
  }

  source_details {
    source_type = "image"
    source_id = var.instance_image_ocid[var.region]
    # Apply this to set the size of the boot volume that is created for this instance.
    # Otherwise, the default boot volume size of the image is used.
    # This should only be specified when source_type is set to "image".
    boot_volume_size_in_gbs = "4352"
  }

  # Apply the following flag only if you wish to preserve the attached boot volume upon destroying this instance
  # Setting this and destroying the instance will result in a boot volume that should be managed outside of this config.
  # When changing this value, make sure to run 'terraform apply' so that it takes effect before the resource is destroyed.
  #preserve_boot_volume = true

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key)
  }


  timeouts {
    create = "60m"
  }
}


resource "oci_core_vlan" "test_vlan" {
    #Required
    cidr_block = var.vlan_cidr_block
    compartment_id = var.compartment_ocid
    vcn_id = var.vcn_id

    #Optional
    #availability_domain = data.oci_identity_availability_domain.ad.name
    
    display_name = var.vlan_display_name
    
    nsg_ids = var.vlan_nsg_ids
    #vlan_tag = var.vlan_vlan_tag
}


resource "oci_core_vnic_attachment" "vnic_attachment" {
  
  count = var.num_instances
  #Required
  create_vnic_details {

    #Optional
    #assign_private_dns_record = false
    #assign_public_ip          = false
    
    #display_name              = var.vnic_display_name
    
    #hostname_label            = var.vnic_hostname_label

    vlan_id = oci_core_vlan.test_vlan.id
  }
  instance_id = oci_core_instance.test_instance[count.index].id

}

#######################################
## Private IPs
#######################################



resource "oci_core_private_ip" "private_ip" {
  count = 48 / var.gbs_for_vm
  #count = 1
  vlan_id = oci_core_vlan.test_vlan.id
}

resource "oci_core_public_ip" "public_ip" {
  count = 48 / var.gbs_for_vm

  #count = 1

  #Required
  compartment_id = var.compartment_ocid
  lifetime       = "RESERVED"

  #Optional
  private_ip_id     = oci_core_private_ip.private_ip[count.index].id
  
}


####################################
## Remote Exec 01
####################################

resource "null_resource" "install_kvm_and_reboot" {
  depends_on = [
    oci_core_instance.test_instance,
  ]
  count = var.num_instances
  provisioner "remote-exec" {
    inline = [
      "# Install OCI CLI packages",
      "sudo dnf -y install oraclelinux-developer-release-el8",
      "sudo dnf -y install python36-oci-cli",
      "echo '================== Download image and drivers ====================='",
      "sudo oci os object bulk-download --bucket-name AutomationScripts --auth instance_principal --dest-dir /home/opc/vgaming",
      "cd /home/opc/vgaming/scripts/",
      "sudo chmod +x *.sh",
      "ls -ltra",
      "./install_packages_in_baremetal.sh",
    ]

    on_failure = continue

    connection {
      type        = "ssh"
      host        = oci_core_instance.test_instance[count.index % var.num_instances].public_ip
      user        = "opc"
      private_key = file(var.ssh_private_key)
    }
  }
}


#######################################
## Sleep during Reboot
#######################################

resource "null_resource" "sleep_during_reboot" {
  depends_on = [null_resource.install_kvm_and_reboot]

  provisioner "local-exec" {
    command = "sleep 180" # 3mins
  }
}

#######################################
## Remote Exec 02
#######################################

resource "null_resource" "execute_shell_script" {
  depends_on = [null_resource.sleep_during_reboot]
  count = var.num_instances
  provisioner "remote-exec" {

    inline = [
      "cd /home/opc/scripts/",
      "sudo chown opc:opc /home/opc/scripts",
      "sudo chmod 777 /home/opc/scripts",
      "./gpu_slicing.sh ${var.gbs_for_vm}",
      "./network.sh ${var.gbs_for_vm} '${oci_core_vlan.test_vlan.vlan_tag}' ${oci_core_vlan.test_vlan.id} ${var.vlan_cidr_block}",
      "nohup ./enable_disable_services.sh >> enable_disable_services.out 2>&1 &",
      "./vm_creation_in_baremetal.sh",
      "nohup ./enable_start_vms_services.sh >> enable_start_vms_services.out 2>&1 &",
    ]

    on_failure = continue

    connection {
      type        = "ssh"
      host        = oci_core_instance.test_instance[count.index % var.num_instances].public_ip
      user        = "opc"
      private_key = file(var.ssh_private_key)
    }

  }
}


data "oci_core_instance_devices" "test_instance_devices" {
  count       = var.num_instances
  instance_id = oci_core_instance.test_instance[count.index].id
}

# Output the private and public IPs of the instance

#output "instance_private_ips" {
#  value = [oci_core_instance.test_instance.*.private_ip]
#}

output "instance_public_ip" {
  value = [oci_core_instance.test_instance.*.public_ip]
}

output "VM_public_ips" {
  value = [oci_core_public_ip.public_ip.*.ip_address]
}

data "oci_identity_availability_domain" "ad" {
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}
