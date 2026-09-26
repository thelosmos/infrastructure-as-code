#!/bin/bash

# Stop execution immediately if any command fails
set -e

# Load BWS_ACCESS_TOKEN and secret UUIDs from the environment file
source .env

echo "Fetching secrets from Bitwarden Secrets Manager..."

# Extract the secret values directly into memory
export PORTAINER_LICENSE_KEY=$(bws secret get $PORTAINER_LICENSE_UUID | jq -r .value)
export VM_OS_USERNAME=$(bws secret get $VM_OS_USERNAME_UUID | jq -r .value)

echo "Secrets loaded. Provisioning Docker and Portainer..."

# Execute the playbook and inject both the license and the SSH username
ansible-playbook -i inventory.ini setup-docker.yml \
  -e "portainer_license_key=$PORTAINER_LICENSE_KEY" \
  -e "ansible_user=$VM_OS_USERNAME"

echo "Ansible provisioning complete!"