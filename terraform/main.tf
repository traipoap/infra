# SPDX-License-Identifier: Apache-2.0

resource "local_file" "ansible_inventory" {
  filename = var.ansible_inventory_path
  content = templatefile("${path.module}/templates/hosts.tpl", {
    super_nodes  = local.super-node
    master_nodes = local.master_nodes
    worker_nodes = local.worker_nodes
  })
}

resource "local_file" "ansible_haproxy" {
  filename = var.ansible_haproxy_path
  content = templatefile("${path.module}/templates/haproxy.tpl", {
    master_nodes = local.master_nodes
    worker_nodes = local.worker_nodes
  })
}

resource "null_resource" "wait_for_ssh" {
  depends_on = [proxmox_virtual_environment_vm.nodes]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for VMs to be SSH ready..."
      HOSTS="${join(" ", concat(local.super-node, local.master_nodes, local.worker_nodes))}"

      for host in $HOSTS; do
        echo "Checking $host..."
        until ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=5 ${var.ssh_username}@"$host" exit 0 2>/dev/null; do
          echo "  - $host not ready yet, sleeping 5s..."
          sleep 5
        done
        echo "  - $host is ready!"
      done
    EOT
  }
}

# สร้างไฟล์ Cloud-init Snippets แบบ Dynamic ทั้ง Cluster
resource "proxmox_virtual_environment_file" "cloud_configs" {
  for_each = local.cluster_nodes

  content_type = "snippets"
  datastore_id = var.datastore_id
  node_name    = var.node_name

  source_raw {
    data      = <<-EOF
    #cloud-config
    hostname: ${each.value.hostname}
    timezone: ${var.timezone}
    users:
      - default
      - name: ${var.ssh_username}
        groups: [sudo]
        shell: /bin/bash
        ssh_authorized_keys:
        ${indent(10, join("\n", [for k in var.ssh_public_keys : "\n${k}"]))}
        sudo: ALL=(ALL) NOPASSWD:ALL
    package_update: true
    packages:
      - qemu-guest-agent
    runcmd:
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
      - echo "done" > /tmp/cloud-config.done
    EOF
    file_name = "${each.key}.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "nodes" {
  for_each = local.cluster_nodes

  name      = each.key
  node_name = var.node_name
  vm_id     = each.value.vm_id

  clone {
    vm_id = each.value.clone_vm_id
    full  = false
  }

  agent { enabled = true }

  cpu {
    cores = each.value.cpu_cores
    type  = "host"
  }

  memory {
    dedicated = each.value.ram_mb
  }

  # --- THE DYNAMIC DISK LOOP ---
  dynamic "disk" {
    for_each = each.value.disks
    content {
      datastore_id = disk.value.datastore_id
      interface    = disk.value.interface
      size         = disk.value.size
    }
  }

  network_device {
    bridge = var.network_bridge
  }

  serial_device {}

  # --- Cloud-config for K3s Worker (agent only, joins the master) ---
  initialization {
    user_data_file_id = proxmox_virtual_environment_file.cloud_configs[each.key].id
    ip_config {
      ipv4 {
        address = "${cidrhost(var.cluster_subnet, each.value.ip_offset)}/24"
        gateway = var.gateway_ip
      }
    }
    dns {
      servers = var.dns_servers
      domain  = "."
    }
  }
  depends_on = [
    proxmox_virtual_environment_file.cloud_configs
  ]
}
