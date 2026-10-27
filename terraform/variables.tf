# SPDX-License-Identifier: Apache-2.0

# Networking
variable "network_bridge" {
  type    = string
  default = "vmbr0"
}

variable "cluster_subnet" {
  type        = string
  default     = "192.168.1.0/24"
}

variable "gateway_ip" {
  type    = string
  default = "192.168.1.1"
}

variable "dns_servers" {
  type    = list(string)
  default = ["8.8.8.8", "8.8.4.4"]
}

# Provider/Agent
variable "proxmox_endpoint" {
  type    = string
  default = "https://proxmox.example.com"
}

variable "proxmox_username" {
  type    = string
  default = "example@pam"
}

variable "proxmox_ssh_username" {
  type    = string
  default = "example"
}

variable "proxmox_password" {
  type    = string
  description = "Another way create a variable password into secrets.auto.tfvars file following reference https://developer.hashicorp.com/terraform/language/values/variables"
  sensitive = true
}

# cloud_configs
variable "datastore_id" {
  type    = string
  default = "local"
}

variable "timezone" {
  type    = string
  default = "Asia/Bangkok"
}

variable "ssh_username" {
  type    = string
  default = "example"
}

variable "ssh_public_keys" {
  type        = list(string)
  description = "Another way create list of SSH public keys into secrets.auto.tfvars file"
  default     = [""]
}

# Resource of main
variable "ansible_inventory_path" {
  type    = string
  default = "../ansible/inventory/hosts"
}

variable "ansible_haproxy_path" {
  type = string
  default = "../ansible/roles/load-balance/templates/haproxy.cfg.j2"
}

# --- Dynamic node scaling ---
# Each role maps to a LIST of VM specs: one entry = one VM.
# Add/remove entries to scale a role, and set node_name per entry to
# spread VMs across PVE nodes. (A map can only hold ONE value per key —
# writing the same key twice silently drops all but the last entry.)
variable "cluster_node_specs" {
  type = map(list(object({
    node_name   = string
    vm_id       = number
    name        = string
    cpu_cores   = number
    ram_mb      = number
    ip          = number
    clone_vm_id = number
    disks = list(object({
      datastore_id = string
      interface    = string
      size         = number
    }))
  })))
  default = {
    super  = []
    master = [
      {
        node_name   = "local"
        vm_id       = 211
        name        = "controlplan-1"
        clone_vm_id = 9000
        cpu_cores   = 2
        ram_mb      = 2048
        ip          = 11
        disks = [
          { datastore_id = "master", interface = "scsi0", size = 32 }
        ]
      },
      {
        node_name   = "proxmox"
        vm_id       = 212
        name        = "controlplan-2"
        clone_vm_id = 9300
        cpu_cores   = 2
        ram_mb      = 2048
        ip          = 12
        disks = [
          { datastore_id = "local", interface = "scsi0", size = 32 }
        ]
      }
    ]
    worker = [
      {
        node_name   = "local"
        vm_id       = 221
        name        = "worker-1"
        clone_vm_id = 9100
        cpu_cores   = 2
        ram_mb      = 4096
        ip          = 21
        disks = [
          { datastore_id = "worker", interface = "scsi0", size = 32 }
        ]
      },
      {
        node_name   = "proxmox"
        vm_id       = 222
        name        = "worker-2"
        clone_vm_id = 9300
        cpu_cores   = 2
        ram_mb      = 4096
        ip          = 22
        disks = [
          { datastore_id = "local", interface = "scsi0", size = 32 }
        ]
      }
    ]
  }
}
