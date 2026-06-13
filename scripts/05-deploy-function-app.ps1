param(
  [string]$TerraformDirectory = "./infra/terraform",
  [string]$PackagePath = "./dist/function.zip"
)

$ErrorActionPreference = "Stop"

Push-Location $TerraformDirectory
$resourceGroup = terraform output -raw resource_group_name
$functionAppName = terraform output -raw function_app_name
Pop-Location

$distDir = Split-Path -Parent $PackagePath
if ($distDir -and -not (Test-Path $distDir)) {
  New-Item -ItemType Directory -Path $distDir | Out-Null
}

if (Test-Path $PackagePath) {
  Remove-Item $PackagePath -Force
}

Push-Location ./app/function
npm install
Pop-Location

Compress-Archive -Path ./app/function/* -DestinationPath $PackagePath

az functionapp deployment source config-zip `
  --resource-group $resourceGroup `
  --name $functionAppName `
  --src $PackagePath

Write-Host "Deployed function package to $functionAppName"

