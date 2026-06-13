resource "azurerm_container_registry" "main" {
  name                          = "acr${replace(local.name, "-", "")}"
  resource_group_name           = data.azurerm_resource_group.main.name
  location                      = var.location
  sku                           = var.acr_sku
  admin_enabled                 = false
  public_network_access_enabled = var.bootstrap_public_access
  tags                          = local.common_tags
}

resource "azurerm_private_endpoint" "acr" {
  name                = "pe-${local.name}-acr"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-acr"
    private_connection_resource_id = azurerm_container_registry.main.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr.id]
  }
}

resource "azurerm_role_assignment" "acr_pull_workload" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
}


