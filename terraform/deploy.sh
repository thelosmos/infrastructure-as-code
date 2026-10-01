#!/bin/bash

# Stop execution immediately if any command fails
set -e

# Load BWS_ACCESS_TOKEN and secret UUIDs from the environment file
source ../.env

# Export Bitwarden provider credentials
export TF_VAR_bws_access_token=$BWS_ACCESS_TOKEN
export TF_VAR_bws_organization_id=$BWS_ORGANIZATION_ID

# Export Bitwarden infrastructure information
export BW_IDENTITY_API_URL="https://identity.bitwarden.com"
export BW_API_URL="https://api.bitwarden.com"

# Map the .env variables directly to Terraform variables
export TF_VAR_proxmox_token_uuid=$(bws secret get $PROXMOX_SECRET_UUID | jq -r .value)
export TF_VAR_vm_os_username_uuid=$(bws secret get $VM_OS_USERNAME_UUID | jq -r .value)
export TF_VAR_vm_password_uuid=$(bws secret get $VM_OS_PASSWORD_UUID | jq -r .value)
export TF_VAR_ssh_pub_key_uuid=$(bws secret get $SSH_PUB_KEY_UUID | jq -r .value)

echo "Starting Proxmox VM provisioning..."

echo "Initializing Terraform..."
terraform init

echo "Applying configuration..."
terraform apply -auto-approve

echo "Deployment complete! Your Docker host is ready."
