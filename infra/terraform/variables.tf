variable "resource_group_name" {
  type        = string
  description = "Existing Azure resource group used for the whole project."
  default     = "Iva-RG"
}

variable "location" {
  type        = string
  description = "Azure region."
  default     = "westeurope"
}

variable "project" {
  type        = string
  description = "Short project prefix."
  default     = "aruo"
}

variable "student_email" {
  type        = string
  description = "Student tag value."
  default     = "ibagaric@algebra.hr"
}

variable "allowed_jump_source_ips" {
  type        = list(string)
  description = "Public CIDR ranges allowed to RDP to the jump VM."
  default     = ["86.32.106.32/32"]
}

variable "jump_admin_username" {
  type        = string
  description = "Local administrator username for the Windows jump VM."
  default     = "azurelabadminiva"
}

variable "jump_admin_password" {
  type        = string
  description = "Local administrator password for the Windows jump VM."
  sensitive   = true
}

variable "postgres_admin_login" {
  type        = string
  description = "PostgreSQL local admin account name."
  default     = "pgadminuser"
}

variable "postgres_entra_admin_upn" {
  type        = string
  description = "UPN of the Entra user configured as PostgreSQL administrator."
  default     = "iva.bagaric@infigo.is"
}

variable "app_gateway_certificate_pfx_path" {
  type        = string
  description = "Path to the self-signed PFX certificate."
  default     = "../../certs/appgw.pfx"
}

variable "app_gateway_certificate_password" {
  type        = string
  description = "Password for the Application Gateway PFX certificate."
  sensitive   = true
}

variable "acr_sku" {
  type        = string
  description = "ACR SKU. Premium is required for private endpoint support."
  default     = "Premium"
}

variable "aks_node_vm_size" {
  type        = string
  description = "AKS node VM size."
  default     = "Standard_B2s"
}

variable "jump_vm_size" {
  type        = string
  description = "Jump VM size."
  default     = "Standard_B1s"
}

variable "bootstrap_public_access" {
  type        = bool
  description = "Keep selected services public during first deployment so Cloud Shell can upload artifacts. Run lockdown script after app deployment."
  default     = true
}
