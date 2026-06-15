# ARUO Azure Project

This repository contains the final project for the Administering Cloud Solutions course. The project implements a secure Azure environment for hosting sample applications through Azure Kubernetes Service and Azure Functions, with private access to supporting services such as PostgreSQL, Storage Account, Key Vault and Azure Container Registry.

The solution was deployed to the existing resource group `Iva-RG` in the Microsoft Partner Network subscription. The deployment was done by using the Azure account `iva.bagaric@infigo.is`, because the student subscription connected to `ibagaric@algebra.hr` was no longer available.

## Repository structure

```text
infra/terraform   Terraform configuration for Azure infrastructure
infra/ARUO-project-ibagaric.docx
                  Final project documentation
infra/video       Video walkthrough of the implemented solution
app/aks           Sample AKS application and Kubernetes manifests
app/function      Sample Azure Function application
scripts           Deployment, evidence collection and shutdown scripts
docs              Architecture diagram and KQL queries
```

## Target Environment

- Subscription: Microsoft Partner Network
- Resource group: `Iva-RG`
- Region: `northeurope`
- Student tag: `ibagaric@algebra.hr`
- Jump VM allowed public IP: `86.32.106.32/32`
- PostgreSQL Entra administrator UPN: `iva.bagaric@infigo.is`
- Container build method: `az acr build`
- Jump VM admin username in the sample variables: `azurelabadminiva`
- Azure account used for deployment: `iva.bagaric@infigo.is`

## Deployed environment

The environment includes:

- Azure Kubernetes Service private cluster
- Azure Function App
- Azure Application Gateway with path-based routing
- Azure Container Registry
- Azure Database for PostgreSQL Flexible Server
- Azure Storage Account with blob container and file share
- Azure Key Vault with stored secrets and certificate
- Windows jump VM in a separate virtual network
- Log Analytics Workspace and monitoring workbook
- Private endpoints and private DNS zones for protected services

Application Gateway exposes two application paths:

- /aks routes to the sample application deployed on AKS
- /functionap routes to the sample Azure Function

Only the jump VM and Application Gateway are intended to have public IP addresses.

## Deployment notes

Terraform is used as the Infrastructure as Code tool. The main configuration is located in infra/terraform.
The solution was deployed in northeurope because PostgreSQL Flexible Server provisioning was restricted in westeurope for the available subscription.
Azure Container Registry uses the Premium SKU because private endpoint support is required for private image access.
Azure File Sync is included in the Terraform configuration as an optional part of the deployment, but it was disabled in the final lab deployment because the Microsoft.StorageSync resource provider could not be registered with the available permissions.

## Basic deployment flow

The deployment can be performed from Azure Cloud Shell or another environment with Azure CLI, Terraform, PowerShell and Git installed.

`cp infra/terraform/terraform.tfvars.example infra/terraform/terraform.tfvars`

`pwsh ./scripts/01-generate-self-signed-cert.ps1`

`pwsh ./scripts/02-terraform-apply.ps1`

`pwsh ./scripts/03-acr-build-image.ps1`

`pwsh ./scripts/04-deploy-aks-app.ps1`

`pwsh ./scripts/05-deploy-function-app.ps1`

`pwsh ./scripts/06-lockdown-public-access.ps1`

Evidence can be collected with:

- `pwsh ./scripts/07-collect-evidence-cli.ps1`
- `python ./scripts/08-list-resources.py`

## Tags
All created resources are configured with the required project tags:
- `university = Algebra`
- `student = ibagaric@algebra.hr`




