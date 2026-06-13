$ErrorActionPreference = "Stop"

$commands = @("az", "terraform", "git", "kubectl", "npm", "python", "pwsh")

foreach ($command in $commands) {
  $found = Get-Command $command -ErrorAction SilentlyContinue
  if ($found) {
    Write-Host "[OK] $command -> $($found.Source)"
  } else {
    Write-Host "[MISSING] $command"
  }
}

Write-Host ""
Write-Host "Azure account:"
az account show --query "{subscription:name, tenant:tenantId, user:user.name}" -o table

Write-Host ""
Write-Host "Resource group:"
az group show --name Iva-RG --query "{name:name, location:location}" -o table

