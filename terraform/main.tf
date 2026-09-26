terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.60.0"
    }
  }
}

# Fetch the Proxmox API Token
data "bws_secret" "proxmox_token" {
  id = var.proxmox_token_uuid
}

# Fetch the VM OS Username
data "bws_secret" "vm_username" {
  id = var.vm_os_username_uuid
}

# Fetch the VM OS Password
data "bws_secret" "vm_password" {
  id = var.vm_password_uuid
}

# Fetch the Public SSH Key
data "bws_secret" "ssh_pub_key" {
  id = var.ssh_pub_key_uuid
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = data.bws_secret.proxmox_token.value
  insecure  = true                            
}

resource "proxmox_virtual_environment_vm" "docker_host" {
  name      = var.vm_name
  node_name = var.target_node
  vm_id     = var.vm_id

  clone {
    vm_id = 9000
    full  = true
  }

  agent {
    enabled = true
  }

  cpu {
    cores = var.cpu_cores
    type  = "host"
  }
  
  memory {
    dedicated = var.memory_mb
  }

  network_device {
    bridge  = "vmbr0"
    vlan_id = var.vlan_id
  }

  disk {
    datastore_id = "vm-storage"
    interface    = "scsi0"
    size         = var.disk_size_gb
    discard      = "on"
  }

  initialization {
    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.gateway
      }
    }
  user_account {
    # Inject credentials directly from BWS memory
    username = data.bws_secret.vm_username.value
    password = data.bws_secret.vm_password.value
    keys     = [data.bws_secret.ssh_pub_key.value]
    }
  }
}