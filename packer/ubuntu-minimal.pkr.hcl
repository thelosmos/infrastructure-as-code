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

source "proxmox-iso" "ubuntu_minimal" {
  # Proxmox Connection
  proxmox_url              = "https://prx01.int.tugatech.xyz:8006/api2/json"
  username                 = "terraform@pve!tf-token" 
  token                    = var.proxmox_token
  insecure_skip_tls_verify = true

  # VM Configuration
  node                 = "prx01"
  vm_id                = 9000
  template_name        = "ubuntu-2404-minimal-template"
  template_description = "Ubuntu 24.04 Minimal built via Packer"

  # ISO Download and Storage
  iso_url          = "https://releases.ubuntu.com/24.04/ubuntu-24.04.1-live-server-amd64.iso"
  iso_checksum     = "file:https://releases.ubuntu.com/24.04/SHA256SUMS"
  iso_storage_pool = "local"
  unmount_iso      = true

  # Hardware Optimizations
  qemu_agent      = true
  machine         = "q35"
  cpu_type        = "host"
  cores           = 2
  memory          = 2048
  scsi_controller = "virtio-scsi-pci"

  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
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
  
  # Dynamic HTTP Content replacing the static http_directory
  http_content = {
    "/meta-data" = ""
    "/user-data" = templatefile("${path.root}/user-data.pkrtpl", {
      build_username = var.vm_os_username
    })
  }
  
  boot_command = [
    "<esc><wait>",
    "e<wait>",
    "<down><down><down><end>",
    " autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ",
    "<f10>"
  ]

  # Packer SSH Authentication (Uses the dynamic BWS username and the dummy password hash from user-data)
  ssh_username   = var.vm_os_username
  ssh_password   = "ubuntu"
  ssh_timeout    = "20m"
}

build {
  sources = ["source.proxmox-iso.ubuntu_minimal"]

  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "echo 'Cleaning up machine IDs and APT cache...'",
      "sudo rm -f /etc/machine-id",
      "sudo touch /etc/machine-id",
      "sudo apt-get clean"
    ]
  }
}