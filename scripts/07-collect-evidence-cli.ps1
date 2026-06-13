param(
  [string]$TerraformDirectory = "./infra/terraform",
  [string]$EvidenceDirectory = "./evidence"
)

$ErrorActionPreference = "Stop"

Push-Location $TerraformDirectory
$resourceGroup = terraform output -raw resource_group_name
Pop-Location

if (-not (Test-Path $EvidenceDirectory)) {
  New-Item -ItemType Directory -Path $EvidenceDirectory | Out-Null
}

az resource list --resource-group $resourceGroup -o table | Tee-Object -FilePath "$EvidenceDirectory/az-resource-list.txt"
az resource list --resource-group $resourceGroup -o json > "$EvidenceDirectory/az-resource-list.json"
az network public-ip list --resource-group $resourceGroup -o table | Tee-Object -FilePath "$EvidenceDirectory/public-ips.txt"
az tag list -o json > "$EvidenceDirectory/tags.json"

Write-Host "Evidence files written to $EvidenceDirectory"

