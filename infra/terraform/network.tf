resource "azurerm_virtual_network" "app" {
  name                = "vnet-${local.name}-app"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  address_space       = ["10.20.0.0/16"]
  tags                = local.common_tags
}

resource "azurerm_virtual_network" "jump" {
  name                = "vnet-${local.name}-jump"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  address_space       = ["10.10.0.0/16"]
  tags                = local.common_tags
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.app.name
  address_prefixes     = ["10.20.1.0/24"]
}

resource "azurerm_subnet" "app_gateway" {
  name                 = "snet-appgw"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.app.name
  address_prefixes     = ["10.20.2.0/24"]
}

resource "azurerm_subnet" "function_integration" {
  name                 = "snet-function-integration"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.app.name
  address_prefixes     = ["10.20.3.0/24"]

  delegation {
    name = "delegation-app-service"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "private_endpoints" {
  name                                      = "snet-private-endpoints"
  resource_group_name                       = data.azurerm_resource_group.main.name
  virtual_network_name                      = azurerm_virtual_network.app.name
  address_prefixes                          = ["10.20.4.0/24"]
  private_endpoint_network_policies_enabled = false
}

resource "azurerm_subnet" "postgres" {
  name                 = "snet-postgres"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.app.name
  address_prefixes     = ["10.20.5.0/24"]

  delegation {
    name = "delegation-postgresql"

    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "jump" {
  name                 = "snet-jump"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.jump.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_network_security_group" "jump" {
  name                = "nsg-${local.name}-jump"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.common_tags

  security_rule {
    name                       = "Allow-RDP-From-Approved-IP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefixes    = var.allowed_jump_source_ips
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-Other-Inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "jump" {
  subnet_id                 = azurerm_subnet.jump.id
  network_security_group_id = azurerm_network_security_group.jump.id
}

resource "azurerm_virtual_network_peering" "jump_to_app" {
  name                      = "peer-jump-to-app"
  resource_group_name       = data.azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.jump.name
  remote_virtual_network_id = azurerm_virtual_network.app.id
}

resource "azurerm_virtual_network_peering" "app_to_jump" {
  name                      = "peer-app-to-jump"
  resource_group_name       = data.azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.app.name
  remote_virtual_network_id = azurerm_virtual_network.jump.id
}

resource "azurerm_private_dns_zone" "aks" {
  name                = "privatelink.${var.location}.azmk8s.io"
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone" "postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone" "file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone" "vault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone" "web" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.common_tags
}

locals {
  private_dns_zones = {
    aks      = azurerm_private_dns_zone.aks.name
    postgres = azurerm_private_dns_zone.postgres.name
    blob     = azurerm_private_dns_zone.blob.name
    file     = azurerm_private_dns_zone.file.name
    vault    = azurerm_private_dns_zone.vault.name
    web      = azurerm_private_dns_zone.web.name
    acr      = azurerm_private_dns_zone.acr.name
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "app" {
  for_each              = local.private_dns_zones
  name                  = "link-app-${each.key}"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = each.value
  virtual_network_id    = azurerm_virtual_network.app.id
  registration_enabled  = false
  tags                  = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "jump" {
  for_each              = local.private_dns_zones
  name                  = "link-jump-${each.key}"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = each.value
  virtual_network_id    = azurerm_virtual_network.jump.id
  registration_enabled  = false
  tags                  = local.common_tags
}

