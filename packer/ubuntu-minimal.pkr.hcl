packer {
  required_plugins {
    proxmox = {
      version = "~> 1.1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "proxmox_token" { 
  type      = string 
  sensitive = true 
}

variable "vm_os_username" { 
  type = string 
}

variable "vm_os_password" {
  type        = string
  sensitive   = true 
}

variable "ssh_pub_key" {
  type        = string
  sensitive   = true 
}

source "proxmox-iso" "ubuntu_minimal" {
  # Proxmox Connection
  proxmox_url              = "https://prx01.int.tugatech.xyz:8006/api2/json"
  username                 = "terraform@pve!terraform" 
  token                    = var.proxmox_token
  insecure_skip_tls_verify = true

  # VM Configuration
  node                 = "prx01"
  vm_id                = 9000
  template_name        = "ubuntu-26041-minimal-template"
  template_description = "Ubuntu 24.04.1 Minimal built via Packer"

  # ISO Download and Storage
  boot_iso {
    type             = "ide"
    iso_file = "local:iso/ubuntu-26.04.1-live-server-amd64.iso"
    unmount          = true
  }

  # Hardware Optimizations
  qemu_agent      = true
  machine         = "q35"
  cpu_type        = "host"
  cores           = 2
  memory          = 2048
  scsi_controller = "virtio-scsi-pci"

  network_adapters {
    bridge   = "vmbr0"
    model    = "virtio"
    vlan_tag = "100" # e.g., "10", "20", "30"
  }

  disks {
    type         = "scsi"
    disk_size    = "20G"
    storage_pool = "vm-storage"
    discard      = true
    format       = "raw"
  }

  # Cloud-Init Drive Configuration
  cloud_init              = true
  cloud_init_storage_pool = "vm-storage"

  # Autoinstall Boot Command for Ubuntu 24.04
  boot_wait      = "10s"
  
# Wrap the offline injection in this block
  additional_iso_files {
    cd_label = "cidata"
    cd_content = {
      "user-data" = templatefile("${path.root}/http/user-data.pkrtpl", {
        vm_os_username = var.vm_os_username
        vm_os_password = var.vm_os_password
        ssh_pub_key    = var.ssh_pub_key
      }) 
      "meta-data" = "instance-id: packer-ubuntu\nlocal-hostname: ubuntu-template\n"
      "network-config" = <<-EOF
        version: 2
        ethernets:
          virtio_nic:
            match:
              name: e*
            dhcp4: true
            dhcp6: false
        EOF
    }
    iso_storage_pool = "local"
    unmount          = true
  }
  
  boot_command = [
    "<esc><wait>",
    "e<wait>",
    "<down><down><down><end>",
    "autoinstall ds=nocloud ip=dhcp systemd.mask=systemd-networkd-wait-online.service --- ",
    "<f10>"
  ]

  # Packer SSH Authentication (Uses the dynamic BWS username and password hash from user-data)
  ssh_username   = var.vm_os_username
  ssh_password   = "ubuntu"
  ssh_timeout    = "20m"
}

build {
  sources = ["source.proxmox-iso.ubuntu_minimal"]

  provisioner "shell" {
    execute_command = "echo 'ubuntu' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "echo 'Cleaning up machine IDs and APT cache...'",
      "sudo rm -f /etc/machine-id",
      "sudo touch /etc/machine-id",
      "sudo apt-get clean"
    ]
  }
}