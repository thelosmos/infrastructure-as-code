proxmox_endpoint = "https://prx01.int.tugatech.xyz:8006/"

# VM Settings
target_node      = "prx01"
vm_name          = "dochost01"
vm_id            = 1000
vlan_id          = 100
ip_address       = "172.25.100.60/24"
gateway          = "172.25.100.1"

# Resource Allocations
cpu_cores        = 2
memory_mb        = 2048
disk_size_gb     = 20