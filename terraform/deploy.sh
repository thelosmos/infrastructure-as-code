#!/bin/bash

# Stop execution immediately if any command fails
set -e

# Load BWS_ACCESS_TOKEN and secret UUIDs from the environment file
source .env

# Map the .env variables directly to Terraform variables
export TF_VAR_proxmox_token_uuid=$PROXMOX_SECRET_UUID
export TF_VAR_vm_os_username_uuid=$VM_OS_USERNAME_UUID
export TF_VAR_vm_password_uuid=$VM_OS_PASSWORD_UUID
export TF_VAR_ssh_pub_key_uuid=$SSH_PUB_KEY_UUID

echo "Starting Proxmox VM provisioning..."

echo "Initializing Terraform..."
terraform init

echo "Applying configuration..."
terraform apply -auto-approve

echo "Deployment complete! Your Docker host is ready."