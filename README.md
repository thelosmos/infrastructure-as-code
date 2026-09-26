# Infrastructure as Code (IaC) Automation Repository

This repository contains an automated, zero-trust infrastructure pipeline designed for provisioning secure computing environments. The current focus is a fully automated Proxmox VE and Docker deployment pipeline, managed strictly through centralized credential orchestration to align with enterprise security frameworks such as NIST SP 800-53 and Zero Trust principles.

## Architecture & Stack

* **Hypervisor:** Proxmox VE (Optimized for environments like Dell PowerEdge R740xd)
* **Secrets Management:** Bitwarden Secrets Manager (BWS)
* **Image Building:** HashiCorp Packer (Ubuntu 24.04 Cloud-Init templates)
* **Provisioning:** HashiCorp Terraform (Infrastructure orchestration and RBAC least-privilege deployment)
* **Configuration:** Ansible (Docker Engine installation and Portainer EE deployment)
* **Container Management:** Portainer Business Edition (EE)

## Core Security Principles

1. **Zero Trust Credentialing:** No passwords, API keys, or private SSH keys are stored on disk, in `.tfvars`, or in version control. All sensitive data is injected dynamically into system memory at runtime via Bitwarden Secrets Manager.
2. **Least Privilege Access:** Proxmox API integration utilizes highly scoped, custom RBAC roles (`TerraformProvisioner`) restricted solely to VM orchestration and console access.
3. **Ephemeral Artifacts:** Packer utilizes temporary password hashes during the ISO build phase, which are aggressively overwritten by Terraform utilizing vault-fetched credentials during cloud-init execution.

## Project Structure

```text
.
├── packer/
│   ├── build.sh                  # Wrapper script for template generation
│   ├── ubuntu-minimal.pkr.hcl    # Packer build configuration
│   └── user-data.pkrtpl          # Cloud-init dynamic OS configuration
├── terraform/
│   ├── deploy.sh                 # Wrapper script for Terraform orchestration
│   ├── main.tf                   # BWS data sources and VM resources
│   ├── variables.tf              # Variable blueprint
│   └── terraform.tfvars          # Non-sensitive network/hardware configs
├── ansible/
│   ├── deploy-ansible.sh         # Wrapper script for software configuration
│   ├── setup-docker.yml          # Docker & Portainer CE/EE deployment playbook
│   ├── inventory.ini             # Target nodes
│   └── requirements.yml          # Ansible module collections required for playbooks
├── .env.example                  # Local environment variable template
├── .gitignore                    # Prevents state files and local secrets from committing
└── LICENSE                       # MIT License
└── Brewfile                      # Dependencies - Can be installed on macOS using Homebrew using the command brew bundle

```

## Prerequisites

Before executing the pipeline, ensure the following tools are installed locally:

* `packer` (v1.10+)
* `terraform` (v1.8+)
* `ansible` (v2.16+) with the `community.docker` collection (`ansible-galaxy collection install community.docker`)
* `bws` (Bitwarden Secrets Manager CLI)
* `jq`

## Configuration

Create a `.env` file in the root directory. This file must **never** be committed to version control. It acts as the local routing table for your Bitwarden vault.

```bash
# .env
export BWS_ACCESS_TOKEN="bws_xxx_YOUR_MACHINE_TOKEN_xxx"

# Bitwarden Secret UUIDs
export PROXMOX_SECRET_UUID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export VM_OS_USERNAME_UUID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export VM_OS_PASSWORD_UUID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export SSH_PUB_KEY_UUID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export PORTAINER_LICENSE_UUID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

```

## Deployment Pipeline

The infrastructure is deployed in three distinct phases.

### Phase 1: Base Image Build

Generates a raw, cloud-init ready Ubuntu 24.04 template in Proxmox.

```bash
cd packer
./build.sh

```

### Phase 2: Infrastructure Provisioning

Clones the template, configures the network adapter, and establishes the secure OS user profile using vault credentials.

```bash
cd ../terraform
./deploy.sh

```

### Phase 3: Software Configuration

Connects via SSH to install Docker Engine, configure user groups, and spin up Portainer Business Edition.

```bash
cd ../ansible
./deploy-ansible.sh

```

Once Phase 3 is complete, the Portainer management interface will be accessible at `https://<YOUR_VM_IP>:9443` with the Business license pre-loaded.