param(
  [string]$TerraformDirectory = "./infra/terraform",
  [string]$RenderedDirectory = "./dist/k8s"
)

$ErrorActionPreference = "Stop"

Push-Location $TerraformDirectory
$resourceGroup = terraform output -raw resource_group_name
$aksName = terraform output -raw aks_name
$acrLoginServer = terraform output -raw acr_login_server
$workloadClientId = terraform output -raw workload_identity_client_id
Pop-Location

az aks get-credentials --resource-group $resourceGroup --name $aksName --overwrite-existing

if (Test-Path $RenderedDirectory) {
  Remove-Item -Recurse -Force $RenderedDirectory
}
New-Item -ItemType Directory -Path $RenderedDirectory | Out-Null

Get-ChildItem ./app/aks/k8s/*.yaml | ForEach-Object {
  $content = Get-Content $_.FullName -Raw
  $content = $content.Replace('${ACR_LOGIN_SERVER}', $acrLoginServer)
  $content = $content.Replace('${WORKLOAD_CLIENT_ID}', $workloadClientId)
  Set-Content -Path (Join-Path $RenderedDirectory $_.Name) -Value $content -Encoding utf8
}

kubectl apply -f $RenderedDirectory
kubectl -n sample rollout status deployment/aks-sample

