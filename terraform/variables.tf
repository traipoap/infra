# SPDX-License-Identifier: Apache-2.0

# Networking
variable "network_bridge" {
  type    = string
  default = "vmbr16"
}

variable "cluster_subnet" {
  type        = string
  default     = "10.10.16.0/24"
}

variable "gateway_ip" {
  type    = string
  default = "10.10.16.1"
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

variable "node_name" {
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
# How many VMs of each role to create.
# e.g. super_nodes = 2, master_nodes = 2, worker_nodes = 2
variable "cluster_node_counts" {
  type = object({
    super  = number
    master = number
    worker = number
  })
  default = {
    super  = 1
    master = 1
    worker = 1
  }
}

# Per-role VM specs. Node N (1-based) of a role gets:
#   name = "<name_base>-N"
#   vm_id = <vm_id_base> + (N - 1)
#   ip    = <ip_base>    + (N - 1)
variable "cluster_node_specs" {
  type = map(object({
    vm_id_base = number
    name_base  = string
    cpu_cores  = number
    ram_mb     = number
    ip_base    = number
    clone_vm_id = number
    disks = list(object({
      datastore_id = string
      interface    = string
      size         = number
    }))
  }))
  default = {
    super = {
      vm_id_base = 200
      name_base  = "super-node"
      clone_vm_id = 2000
      cpu_cores  = 1
      ram_mb     = 2048
      ip_base    = 4
      disks = [
        { datastore_id = "data-st1000", interface = "scsi0", size = 32 },
        { datastore_id = "data-st1000", interface = "scsi1", size = 100 }
      ]
    }
    master = {
      vm_id_base = 210
      name_base  = "k3s-master"
      clone_vm_id = 4000
      cpu_cores  = 2
      ram_mb     = 8192
      ip_base    = 11
      disks = [
        { datastore_id = "system-hs512", interface = "scsi0", size = 32 }
      ]
    }
    worker = {
      vm_id_base = 220
      name_base  = "k3s-worker"
      clone_vm_id = 3000
      cpu_cores  = 2
      ram_mb     = 8192
      ip_base    = 21
      disks = [
        { datastore_id = "st500", interface = "scsi0", size = 32 }
      ]
    }
  }
}
