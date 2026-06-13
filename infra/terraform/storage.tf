resource "azurerm_storage_account" "main" {
  name                            = "st${replace(local.name, "-", "")}"
  resource_group_name             = data.azurerm_resource_group.main.name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  public_network_access_enabled   = var.bootstrap_public_access
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = true
  tags                            = local.common_tags

  blob_properties {
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }
}

resource "azurerm_storage_container" "app" {
  name                  = "appdata"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

resource "azurerm_storage_share" "onprem_sync" {
  name               = "onprem-sync"
  storage_account_id = azurerm_storage_account.main.id
  quota              = 32
  enabled_protocol   = "SMB"
  access_tier        = "TransactionOptimized"
}

resource "azurerm_private_endpoint" "blob" {
  name                = "pe-${local.name}-blob"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-blob"
    private_connection_resource_id = azurerm_storage_account.main.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }
}

resource "azurerm_private_endpoint" "file" {
  name                = "pe-${local.name}-file"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-file"
    private_connection_resource_id = azurerm_storage_account.main.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.file.id]
  }
}

resource "azurerm_storage_sync" "main" {
  count               = var.enable_file_sync ? 1 : 0
  name                = "sync-${local.name}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  tags                = local.common_tags
}

resource "azurerm_storage_sync_group" "main" {
  count           = var.enable_file_sync ? 1 : 0
  name            = "sync-group-onprem"
  storage_sync_id = azurerm_storage_sync.main[0].id
}

resource "azurerm_storage_sync_cloud_endpoint" "main" {
  count                 = var.enable_file_sync ? 1 : 0
  name                  = "cloud-endpoint-onprem"
  storage_sync_group_id = azurerm_storage_sync_group.main[0].id
  file_share_name       = azurerm_storage_share.onprem_sync.name
  storage_account_id    = azurerm_storage_account.main.id
}

resource "azurerm_role_assignment" "workload_blob" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
}

resource "azurerm_role_assignment" "workload_file" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage File Data SMB Share Contributor"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
}



