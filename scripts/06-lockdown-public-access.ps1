param(
  [string]$TerraformDirectory = "./infra/terraform"
)

$ErrorActionPreference = "Stop"

Push-Location $TerraformDirectory
$resourceGroup = terraform output -raw resource_group_name
$keyVaultName = terraform output -raw key_vault_name
$storageAccountName = terraform output -raw storage_account_name
$acrName = terraform output -raw acr_name
$functionAppName = terraform output -raw function_app_name
Pop-Location

az keyvault update --resource-group $resourceGroup --name $keyVaultName --public-network-access Disabled
az storage account update --resource-group $resourceGroup --name $storageAccountName --public-network-access Disabled
az acr update --resource-group $resourceGroup --name $acrName --public-network-enabled false
az functionapp update --resource-group $resourceGroup --name $functionAppName --set publicNetworkAccess=Disabled

Write-Host "Public network access disabled for Key Vault, Storage, ACR, and Function App."

