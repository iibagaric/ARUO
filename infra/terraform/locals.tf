data "azurerm_client_config" "current" {}
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azuread_user" "postgres_admin" {
  user_principal_name = var.postgres_entra_admin_upn
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "random_password" "postgres_admin" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>?"
}

resource "random_uuid" "workbook" {}

locals {
  suffix = random_string.suffix.result
  name   = "${var.project}-${local.suffix}"

  required_tags = {
    university = "Algebra"
    student    = var.student_email
  }

  common_tags = merge(local.required_tags, {
    project = "aruo"
    env     = "lab"
  })
}

