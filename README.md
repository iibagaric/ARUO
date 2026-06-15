# ARUO Azure Project

Infrastructure as Code project for a secure Azure application environment in the existing resource group `Iva-RG`.

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

## Repository Structure

```text
infra/terraform   Terraform infrastructure
app/aks           Sample container app and Kubernetes manifests
app/function      Sample Azure Function code
scripts           Deployment, evidence, and shutdown scripts
docs              Project documentation, diagrams, and Kusto queries
```

## Deployment Flow

Run these commands from Azure Cloud Shell or another terminal where Azure CLI, Terraform, and Git are installed.

1. Log in and select the subscription:

   ```bash
   az login
   az account set --subscription "Microsoft Partner Network"
   az account show
   ```

2. Prepare Terraform variables:

   ```bash
   cp infra/terraform/terraform.tfvars.example infra/terraform/terraform.tfvars
   code infra/terraform/terraform.tfvars
   ```

3. Generate a self-signed certificate for Application Gateway:

   ```bash
   pwsh ./scripts/01-generate-self-signed-cert.ps1
   ```

4. Deploy infrastructure:

   ```bash
   pwsh ./scripts/02-terraform-apply.ps1
   ```

5. Build and push the AKS image using Azure Container Registry Tasks:

   ```bash
   pwsh ./scripts/03-acr-build-image.ps1
   ```

6. Deploy the AKS sample app:

   ```bash
   pwsh ./scripts/04-deploy-aks-app.ps1
   ```

7. Deploy the Function App sample:

   ```bash
   pwsh ./scripts/05-deploy-function-app.ps1
   ```

8. Disable public network access after bootstrap:

   ```bash
   pwsh ./scripts/06-lockdown-public-access.ps1
   ```

9. Collect evidence:

   ```bash
   pwsh ./scripts/07-collect-evidence-cli.ps1
   python ./scripts/08-list-resources.py
   ```

## Important Notes

- Azure Container Registry Private Link requires Premium SKU. This project uses Premium by default so AKS can pull images privately after bootstrap.
- PostgreSQL Flexible Server was deployed in North Europe because the subscription was restricted from provisioning PostgreSQL Flexible Server in West Europe.
- Azure File Sync resources are controlled by `enable_file_sync`. The sample variables set it to `false` because the lab subscription did not have the `Microsoft.StorageSync` provider registered and the account could not register subscription-level providers.
- The Function App uses Node 24 because Node 20 reached end of life and was not used in the final deployment.
- Some services are temporarily public during bootstrap because Cloud Shell must upload packages, images, and certificates. The lockdown script disables public access after deployment.
- Do not commit `terraform.tfvars`, certificates, state files, or evidence outputs.
