#!/usr/bin/bash

# Exit immediately if a command fails
set -e

echo "Updating system package lists..."
sudo apt update

echo "Installing jq and Ansible..."
sudo apt install -y jq ansible

echo "Installing prerequisites for HashiCorp repository..."
sudo apt install -y wget gpg lsb-release curl

echo "Adding HashiCorp GPG key..."
# The --yes flag prevents prompts if the key already exists
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg --yes

echo "Adding HashiCorp repository..."
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

echo "Updating package lists with new HashiCorp repo..."
sudo apt update

echo "Installing Packer and Terraform..."
sudo apt install -y packer terraform

echo "Installing xorriso..."
sudo apt install -y xorriso

echo "Installing Bitwarden Secrets Manager (bws)..."
curl -sSL https://bws.bitwarden.com/install | sh

# Move the downloaded bws binary into the system PATH
if [ -f "bws" ]; then
    sudo mv bws /usr/local/bin/
    echo "bws successfully moved to /usr/local/bin/"
else
    echo "Warning: bws binary not found in the current directory. You may need to move it manually."
fi

echo "All dependencies installed successfully!"