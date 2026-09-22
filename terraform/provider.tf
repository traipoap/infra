# SPDX-License-Identifier: Apache-2.0

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  username = var.proxmox_username
  password = var.proxmox_password

  insecure = true

  ssh {
    agent    = true
    username = var.proxmox_ssh_username
    password = var.proxmox_password
  }
}
