# SPDX-License-Identifier: Apache-2.0

# Generate the node list from the per-role spec lists (one entry = one VM)
locals {
  cluster_nodes = merge(
    { for entry in var.cluster_node_specs.super : entry.name => {
        node_name   = entry.node_name
        vm_id       = entry.vm_id
        role        = "super"
        cpu_cores   = entry.cpu_cores
        ram_mb      = entry.ram_mb
        ip_offset   = entry.ip
        hostname    = entry.name
        clone_vm_id = entry.clone_vm_id
        disks       = entry.disks
      }
    },
    { for entry in var.cluster_node_specs.master : entry.name => {
        node_name   = entry.node_name
        vm_id       = entry.vm_id
        role        = "master"
        cpu_cores   = entry.cpu_cores
        ram_mb      = entry.ram_mb
        ip_offset   = entry.ip
        hostname    = entry.name
        clone_vm_id = entry.clone_vm_id
        disks       = entry.disks
      }
    },
    { for entry in var.cluster_node_specs.worker : entry.name => {
        node_name   = entry.node_name
        vm_id       = entry.vm_id
        role        = "worker"
        cpu_cores   = entry.cpu_cores
        ram_mb      = entry.ram_mb
        ip_offset   = entry.ip
        hostname    = entry.name
        clone_vm_id = entry.clone_vm_id
        disks       = entry.disks
      }
    }
  )
}

locals {
  super-node = [for k, v in local.cluster_nodes : cidrhost(var.cluster_subnet, v.ip_offset) if v.role == "super"]
  master_nodes = [for k, v in local.cluster_nodes : cidrhost(var.cluster_subnet, v.ip_offset) if v.role == "master"]
  worker_nodes = [for k, v in local.cluster_nodes : cidrhost(var.cluster_subnet, v.ip_offset) if v.role == "worker"]
}

# Fail early if two roles' IP ranges overlap (e.g. too many super nodes)
locals {
  check_cluster_capacity = length(concat(
    local.super-node,
    local.master_nodes,
    local.worker_nodes
  )) == length(toset(concat(
    local.super-node,
    local.master_nodes,
    local.worker_nodes
  )))
}
