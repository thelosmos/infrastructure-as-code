terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.60.0"
    }
    bitwarden-secrets = {
      source  = "bitwarden/bitwarden-secrets"
    }
  }
}

provider "bitwarden-secrets" {
  # The provider will automatically authenticate using the BWS_ACCESS_TOKEN 
  # environment variable already loaded by your deploy.sh script
  
  access_token    = var.bws_access_token
  organization_id = var.bws_organization_id
  identity_url    = var.bws_identity_url
  api_url         = var.bws_api_url
}

# Fetch the Proxmox Token ID prefix (e.g., root@pam!terraform)
data "bitwarden-secrets_secret" "proxmox_token_id" {
  id = var.proxmox_token_id_uuid
}

# Fetch the actual Proxmox API Token secret
data "bitwarden-secrets_secret" "proxmox_token" {
  id = var.proxmox_token_uuid
}

# Fetch the VM OS Username
data "bitwarden-secrets_secret" "vm_username" {
  id = var.vm_os_username_uuid
}

# Fetch the VM OS Password
data "bitwarden-secrets_secret" "vm_password" {
  id = var.vm_password_uuid
}

# Fetch the Public SSH Key
data "bitwarden-secrets_secret" "ssh_pub_key" {
  id = var.vm_ssh_pub_key_uuid
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = "${data.bitwarden-secrets_secret.proxmox_token_id.value}=${data.bitwarden-secrets_secret.proxmox_token.value}"
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
    datastore_id = "vm-storage"
    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.gateway
      }
    }
    user_account {
      # Inject credentials directly from BWS memory
      username = data.bitwarden-secrets_secret.vm_username.value
      password = data.bitwarden-secrets_secret.vm_password.value
      keys     = [data.bitwarden-secrets_secret.ssh_pub_key.value]
    }
  }
}