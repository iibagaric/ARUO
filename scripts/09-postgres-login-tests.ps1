param(
  [string]$TerraformDirectory = "./infra/terraform",
  [string]$DatabaseName = "postgres"
)

$ErrorActionPreference = "Stop"

Push-Location $TerraformDirectory
$serverFqdn = terraform output -raw postgres_fqdn
$keyVaultName = terraform output -raw key_vault_name
Pop-Location

$password = az keyvault secret show --vault-name $keyVaultName --name postgres-admin-password --query value -o tsv
$adminUser = "pgadminuser"

Write-Host "Testing password authentication..."
$env:PGPASSWORD = $password
psql "host=$serverFqdn port=5432 dbname=$DatabaseName user=$adminUser sslmode=require" -c "select current_user, now();"

Write-Host "Testing Entra authentication..."
$token = az account get-access-token --resource https://ossrdbms-aad.database.windows.net --query accessToken -o tsv
$entraUser = az account show --query user.name -o tsv
$env:PGPASSWORD = $token
psql "host=$serverFqdn port=5432 dbname=$DatabaseName user=$entraUser sslmode=require" -c "select current_user, now();"

$env:PGPASSWORD = $null

