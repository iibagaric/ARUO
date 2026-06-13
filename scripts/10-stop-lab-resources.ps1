param(
  [string]$TerraformDirectory = "./infra/terraform"
)

$ErrorActionPreference = "Stop"

Push-Location $TerraformDirectory
$resourceGroup = terraform output -raw resource_group_name
$aksName = terraform output -raw aks_name
Pop-Location

$jumpVmName = az vm list --resource-group $resourceGroup --query "[?contains(name, 'jump')].name | [0]" -o tsv

az aks stop --resource-group $resourceGroup --name $aksName
az vm deallocate --resource-group $resourceGroup --name $jumpVmName

Write-Host "Stopped AKS cluster and deallocated jump VM."

