param(
  [string]$TerraformDirectory = "./infra/terraform",
  [string]$ImageTag = "v1"
)

$ErrorActionPreference = "Stop"

Push-Location $TerraformDirectory
$acrName = terraform output -raw acr_name
$acrLoginServer = terraform output -raw acr_login_server
Pop-Location

az acr build `
  --registry $acrName `
  --image "aks-sample:$ImageTag" `
  ./app/aks

Write-Host "Built image $acrLoginServer/aks-sample:$ImageTag"

