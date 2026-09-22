# SPDX-License-Identifier: Apache-2.0

# Generate the node list from counts + per-role specs
locals {
  cluster_nodes = merge(
    { for i in range(var.cluster_node_counts.super) : "super-node-${i + 1}" => {
        vm_id       = var.cluster_node_specs.super.vm_id_base + i
        role        = "super"
        cpu_cores   = var.cluster_node_specs.super.cpu_cores
        ram_mb      = var.cluster_node_specs.super.ram_mb
        ip_offset   = var.cluster_node_specs.super.ip_base + i
        hostname    = "super-node-${i + 1}"
        clone_vm_id = var.cluster_node_specs.super.clone_vm_id
        disks       = var.cluster_node_specs.super.disks
      }
    },
    { for i in range(var.cluster_node_counts.master) : "k3s-master-${i + 1}" => {
        vm_id       = var.cluster_node_specs.master.vm_id_base + i
        role        = "master"
        cpu_cores   = var.cluster_node_specs.master.cpu_cores
        ram_mb      = var.cluster_node_specs.master.ram_mb
        ip_offset   = var.cluster_node_specs.master.ip_base + i
        hostname    = "k3s-master-${i + 1}"
        clone_vm_id = var.cluster_node_specs.master.clone_vm_id
        disks       = var.cluster_node_specs.master.disks
      }
    },
    { for i in range(var.cluster_node_counts.worker) : "k3s-worker-${i + 1}" => {
        vm_id       = var.cluster_node_specs.worker.vm_id_base + i
        role        = "worker"
        cpu_cores   = var.cluster_node_specs.worker.cpu_cores
        ram_mb      = var.cluster_node_specs.worker.ram_mb
        ip_offset   = var.cluster_node_specs.worker.ip_base + i
        hostname    = "k3s-worker-${i + 1}"
        clone_vm_id = var.cluster_node_specs.worker.clone_vm_id
        disks       = var.cluster_node_specs.worker.disks
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
