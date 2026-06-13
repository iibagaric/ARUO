resource "azurerm_key_vault" "main" {
  name                          = "kv-${local.name}"
  location                      = var.location
  resource_group_name           = data.azurerm_resource_group.main.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  enable_rbac_authorization     = true
  purge_protection_enabled      = false
  soft_delete_retention_days    = 7
  public_network_access_enabled = var.bootstrap_public_access
  tags                          = local.common_tags
}

resource "azurerm_private_endpoint" "key_vault" {
  name                = "pe-${local.name}-kv"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-kv"
    private_connection_resource_id = azurerm_key_vault.main.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.vault.id]
  }
}

resource "azurerm_role_assignment" "deployer_key_vault_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "postgres_admin_password" {
  name         = "postgres-admin-password"
  value        = random_password.postgres_admin.result
  key_vault_id = azurerm_key_vault.main.id
  tags         = local.common_tags

  depends_on = [azurerm_role_assignment.deployer_key_vault_admin]
}

resource "azurerm_key_vault_certificate" "app_gateway" {
  name         = "appgw-self-signed"
  key_vault_id = azurerm_key_vault.main.id
  tags         = local.common_tags

  certificate {
    contents = filebase64(var.app_gateway_certificate_pfx_path)
    password = var.app_gateway_certificate_password
  }

  depends_on = [azurerm_role_assignment.deployer_key_vault_admin]
}

resource "azurerm_role_assignment" "workload_key_vault_secrets" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
}

resource "azurerm_role_assignment" "appgw_key_vault_secrets" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app_gateway.principal_id
}

resource "azurerm_role_assignment" "appgw_key_vault_certificates" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Certificate User"
  principal_id         = azurerm_user_assigned_identity.app_gateway.principal_id
}


