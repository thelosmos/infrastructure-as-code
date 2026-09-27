#!/bin/bash

set -e

# 1. Load the BWS_ACCESS_TOKEN and secret UUIDs from your local environment file
source ../.env

echo "Fetching secrets from Bitwarden Secrets Manager..."

# 2. Extract each secret and map it to the correct Packer variable
export PKR_VAR_proxmox_token=$(bws secret get $PROXMOX_SECRET_UUID | jq -r .value)
export PKR_VAR_vm_os_username=$(bws secret get $VM_OS_USERNAME_UUID | jq -r .value)

echo "Secrets loaded. Initializing Packer..."

# 3. Initialize plugins and run the build
packer init .
packer build ubuntu-minimal.pkr.hcl

echo "Packer build complete! Template 9000 is ready."