# ARUO Project Documentation Notes

Use this file as the basis for the final Word document. Add Azure Portal screenshots after deployment.

## 1. Abstract

The project deploys a secure Azure environment for a multi-container application. The solution uses Azure Kubernetes Service, Azure Function App, PostgreSQL Flexible Server, Storage Account, Key Vault, Container Registry, Application Gateway, and Azure Monitor.

## 2. Introduction

The environment is deployed with Terraform into the existing resource group `Iva-RG` in North Europe. Public exposure is limited to the jump VM and Application Gateway. Other platform services are accessed privately after bootstrap lockdown. North Europe was used because PostgreSQL Flexible Server provisioning was restricted in West Europe for the available subscription.

## 3. Cloud Object Management

### 3.1 Project solved using IaC

Terraform files are stored in `infra/terraform`. Deployment is performed with `scripts/02-terraform-apply.ps1`.

### 3.2 Solution diagram

The Mermaid diagram is stored in `docs/architecture.mmd`.

### 3.3 Resources listed by Azure CLI

Use `scripts/07-collect-evidence-cli.ps1`.

### 3.4 Resources listed by Python

Use `scripts/08-list-resources.py`.

### 3.5 Tags

Required tags:

| Tag | Value |
| --- | --- |
| university | Algebra |
| student | ibagaric@algebra.hr |

## 4. Security Settings and Subscriptions

The solution uses user-assigned managed identities and least-privilege RBAC:

| Identity | Purpose |
| --- | --- |
| AKS control plane identity | Private DNS and network permissions |
| AKS workload identity | ACR, Storage, and Key Vault access for pods |
| Application Gateway identity | Key Vault certificate access |

## 5. Compute Management

- AKS private cluster with workload identity and automatic patch upgrades.
- Function App sample endpoint at `/functionap`.
- ACR image built with `az acr build`.
- Windows jump VM with platform-managed patching.

## 6. Advanced Storage Management

- Storage account with blob container and Azure Files share.
- Private endpoints for blob and file.
- Azure Files share. Azure File Sync resources are optional and controlled by `enable_file_sync`; this was set to `false` in the lab because `Microsoft.StorageSync` was not registered and could not be registered by the account.
- PostgreSQL Flexible Server with private networking and automated backup retention.

## 7. Advanced Virtual Network Management

- Two VNETs: application VNET and jump VNET.
- Separate subnets for AKS, Application Gateway, Function integration, PostgreSQL, private endpoints, and jump VM.
- Only two public IP resources: jump VM and Application Gateway.
- Jump VM NSG allows RDP only from `86.32.106.32/32`.

## 8. Monitoring and Backup

- Log Analytics Workspace.
- VM Security logs through Azure Monitor Agent and Data Collection Rule.
- AKS container logs through Container Insights.
- Storage and Key Vault diagnostic settings.
- PostgreSQL backup retention.
- Azure Workbook with KQL queries.

## 9. Evidence to Capture

Capture screenshots for:

1. Resource group overview.
2. Tags on resources.
3. Two public IP addresses only.
4. VNETs, subnets, peering, and private DNS zones.
5. Jump VM NSG rule.
6. Key Vault secrets and certificate.
7. Managed identities and RBAC assignments.
8. AKS cluster and deployed sample app.
9. Function App and deployed function.
10. ACR repository with image.
11. Application Gateway listener, certificate, and routing.
12. Successful browser or curl tests for `/aks` and `/functionap`.
13. PostgreSQL login with password and Entra account.
14. Storage account, blob container, file share, and Azure File Sync.
15. Log Analytics queries and workbook CPU visualization.

