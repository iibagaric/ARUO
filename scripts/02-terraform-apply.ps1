param(
  [string]$TerraformDirectory = "./infra/terraform"
)

$ErrorActionPreference = "Stop"

Push-Location $TerraformDirectory
terraform init
terraform fmt -recursive
terraform validate
terraform apply
Pop-Location

