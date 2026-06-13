resource "azurerm_postgresql_flexible_server" "main" {
  name                          = "pg-${local.name}"
  resource_group_name           = data.azurerm_resource_group.main.name
  location                      = var.location
  version                       = "16"
  delegated_subnet_id           = azurerm_subnet.postgres.id
  private_dns_zone_id           = azurerm_private_dns_zone.postgres.id
  public_network_access_enabled = false
  administrator_login           = var.postgres_admin_login
  administrator_password        = random_password.postgres_admin.result
  storage_mb                    = 32768
  sku_name                      = "B_Standard_B1ms"
  backup_retention_days         = 7
  geo_redundant_backup_enabled  = false
  tags                          = local.common_tags

  authentication {
    active_directory_auth_enabled = true
    password_auth_enabled         = true
    tenant_id                     = data.azurerm_client_config.current.tenant_id
  }

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.app,
    azurerm_private_dns_zone_virtual_network_link.jump
  ]
}

resource "azurerm_postgresql_flexible_server_active_directory_administrator" "main" {
  server_name         = azurerm_postgresql_flexible_server.main.name
  resource_group_name = data.azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azuread_user.postgres_admin.object_id
  principal_name      = var.postgres_entra_admin_upn
  principal_type      = "User"
}


