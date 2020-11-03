provider "ibm" {}

module "camtags" {
  source = "../Modules/camtags"
}

resource "tls_private_key" "keyPairForAnsibleUser" {
 algorithm = "RSA"
}

resource "ibm_compute_ssh_key" "ansible_ssh_key" {
    public_key          = "${tls_private_key.keyPairForAnsibleUser.public_key_openssh}"
    label               = "camKeyForAnsibleUser"
}
 
variable "memory-size" {
  description = "amount of ram for vm"
}
variable "core-num" {
  description = "num of cores for vm"
}
  
variable "disk-size" {
  description = "disk size"
}
  
variable "public_ssh_key" {
  description = "Public SSH key used to connect to the virtual guest"
}

variable "datacenter" {
  description = "Softlayer datacenter where infrastructure resources will be deployed"
}

variable "hostname" {
  description = "Hostname of the virtual instance (small flavor) to be deployed"
  default     = "debian-small"
}

# This will create a new SSH key that will show up under the \
# Devices>Manage>SSH Keys in the SoftLayer console.
resource "ibm_compute_ssh_key" "orpheus_public_key" {
  label      = "Orpheus Public Key"
  public_key = "${var.public_ssh_key}"
}

variable "domain" {
  description = "VM domain"
}

# Create a new virtual guest using image "Debian"
resource "ibm_compute_vm_instance" "debian_small_virtual_guest" {
  hostname                 = "${var.hostname}"
  os_reference_code        = "DEBIAN_9_64"
  domain                   = "${var.domain}"
  datacenter               = "${var.datacenter}"
  network_speed            = 10
  hourly_billing           = true
  private_network_only     = false
  cores                    = "${var.core-num}"
  memory                   = "${var.memory-size}"
  disks                    = ["${var.disk-size}"]
  user_metadata            = "{\"value\":\"newvalue\"}"
  dedicated_acct_host_only = false
  local_disk               = false
  ssh_key_ids              = ["${ibm_compute_ssh_key.orpheus_public_key.id}", "${ibm_compute_ssh_key.ansible_ssh_key.id}"]
  tags                     = ["${module.camtags.tagslist}"]
}

output "instance_ip_addr" {
   value                 = "${ibm_compute_vm_instance.debian_small_virtual_guest.ipv4_address}"
   description           = "The public IP address of the main server instance."
 }

output "private_key" {
   value                 = "${tls_private_key.keyPairForAnsibleUser.private_key_pem}"
   description           = "The private key of the main server instance."
   sensitive             = true
 }

