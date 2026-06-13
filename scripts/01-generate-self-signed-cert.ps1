param(
  [string]$DnsName = "aruo.local",
  [string]$OutputPath = "./certs/appgw.pfx",
  [Parameter(Mandatory = $false)]
  [securestring]$Password
)

$ErrorActionPreference = "Stop"

$certDir = Split-Path -Parent $OutputPath
if ($certDir -and -not (Test-Path $certDir)) {
  New-Item -ItemType Directory -Path $certDir | Out-Null
}

if ($IsWindows -and (Get-Command New-SelfSignedCertificate -ErrorAction SilentlyContinue)) {
  if (-not $Password) {
    $Password = Read-Host "Enter PFX password. Use the same value in terraform.tfvars" -AsSecureString
  }

  $cert = New-SelfSignedCertificate `
    -DnsName $DnsName `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -KeyAlgorithm RSA `
    -KeyLength 2048 `
    -NotAfter (Get-Date).AddYears(1)

  Export-PfxCertificate `
    -Cert "Cert:\CurrentUser\My\$($cert.Thumbprint)" `
    -FilePath $OutputPath `
    -Password $Password | Out-Null
} else {
  if (-not (Get-Command openssl -ErrorAction SilentlyContinue)) {
    throw "OpenSSL is required on non-Windows shells."
  }

  $plainPassword = Read-Host "Enter PFX password. Use the same value in terraform.tfvars"
  $keyPath = Join-Path $certDir "appgw.key"
  $crtPath = Join-Path $certDir "appgw.crt"

  openssl req -x509 -nodes -newkey rsa:2048 `
    -keyout $keyPath `
    -out $crtPath `
    -days 365 `
    -subj "/CN=$DnsName"

  openssl pkcs12 -export `
    -out $OutputPath `
    -inkey $keyPath `
    -in $crtPath `
    -password "pass:$plainPassword"
}

Write-Host "Created $OutputPath"
