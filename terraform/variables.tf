# Bitwarden Provider Credentials
variable "bws_access_token" { 
    type = string
    sensitive = true 
    }
variable "bws_organization_id" {type = string }
variable "bws_identity_url" {
    type = string
    default = "https://identity.bitwarden.com"
    }
variable "bws_api_url" {
    type = string
    default = "https://api.bitwarden.com"
    }

# Proxmox Authentication
variable "proxmox_endpoint" { type = string }

# VM Identification and Network
variable "target_node" { type = string }
variable "vm_name" { type = string }
variable "vm_id" { type = number }
variable "vlan_id" { type = number }
variable "ip_address" { type = string }
variable "gateway" { type = string }
variable "vm_ssh_pub_key_uuid" { type = string }

# Hardware Resources
variable "cpu_cores" { type = number }
variable "memory_mb" { type = number }
variable "disk_size_gb" { type = number }

# Cloud-Init OS Credentials
variable "proxmox_token_uuid" { type = string }
variable "proxmox_token_id_uuid" { type = string }
variable "vm_os_username_uuid" { type = string }
variable "vm_password_uuid" { type = string }