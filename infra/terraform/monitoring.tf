resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${local.name}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags
}

resource "azurerm_monitor_data_collection_rule" "vm_security" {
  name                = "dcr-${local.name}-vm-security"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.common_tags

  destinations {
    log_analytics {
      name                  = "law"
      workspace_resource_id = azurerm_log_analytics_workspace.main.id
    }
  }

  data_sources {
    windows_event_log {
      name           = "security-events"
      streams        = ["Microsoft-Event"]
      x_path_queries = ["Security!*"]
    }

    performance_counter {
      name                          = "vm-cpu"
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60
      counter_specifiers            = ["\\Processor(_Total)\\% Processor Time"]
    }
  }

  data_flow {
    streams      = ["Microsoft-Event", "Microsoft-Perf"]
    destinations = ["law"]
  }
}

resource "azurerm_virtual_machine_extension" "ama" {
  name                       = "AzureMonitorWindowsAgent"
  virtual_machine_id         = azurerm_windows_virtual_machine.jump.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.0"
  automatic_upgrade_enabled  = true
  auto_upgrade_minor_version = true
  tags                       = local.common_tags
}

resource "azurerm_monitor_data_collection_rule_association" "jump" {
  name                    = "assoc-${local.name}-jump"
  target_resource_id      = azurerm_windows_virtual_machine.jump.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.vm_security.id
}

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "diag-keyvault-to-law"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "AuditEvent"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "storage_blob" {
  name                       = "diag-blob-to-law"
  target_resource_id         = "${azurerm_storage_account.main.id}/blobServices/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  metric {
    category = "Transaction"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "app_gateway" {
  name                       = "diag-appgw-to-law"
  target_resource_id         = azurerm_application_gateway.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }

  enabled_log {
    category = "ApplicationGatewayPerformanceLog"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "postgres" {
  name                       = "diag-postgres-to-law"
  target_resource_id         = azurerm_postgresql_flexible_server.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "PostgreSQLLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_application_insights_workbook" "main" {
  name                = random_uuid.workbook.result
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  display_name        = "ARUO monitoring workbook"
  source_id           = lower(azurerm_log_analytics_workspace.main.id)
  category            = "workbook"
  tags                = local.common_tags

  data_json = jsonencode({
    version = "Notebook/1.0"
    items = [
      {
        type = 1
        content = {
          json = "# ARUO monitoring queries"
        }
      },
      {
        type = 3
        content = {
          version      = "KqlItem/1.0"
          query        = "Event | where TimeGenerated > ago(24h) | where EventLog == 'Security' | summarize Count=count() by EventID, Activity | order by Count desc"
          title        = "Windows security events"
          queryType    = 0
          resourceType = "microsoft.operationalinsights/workspaces"
        }
      },
      {
        type = 3
        content = {
          version      = "KqlItem/1.0"
          query        = "ContainerLogV2 | where TimeGenerated > ago(24h) | summarize Count=count() by PodNamespace, PodName, ContainerName | order by Count desc"
          title        = "AKS container logs"
          queryType    = 0
          resourceType = "microsoft.operationalinsights/workspaces"
        }
      },
      {
        type = 3
        content = {
          version      = "KqlItem/1.0"
          query        = "AzureDiagnostics | where TimeGenerated > ago(24h) | where ResourceProvider in ('MICROSOFT.KEYVAULT','MICROSOFT.STORAGE') | summarize Count=count() by ResourceProvider, OperationName, ResultType"
          title        = "Storage and Key Vault access"
          queryType    = 0
          resourceType = "microsoft.operationalinsights/workspaces"
        }
      },
      {
        type = 3
        content = {
          version      = "KqlItem/1.0"
          query        = "Perf | where TimeGenerated > ago(24h) | where ObjectName == 'Processor' and CounterName == '% Processor Time' | summarize AvgCpu=avg(CounterValue) by bin(TimeGenerated, 5m), Computer | render timechart"
          title        = "Jump VM CPU"
          queryType    = 0
          resourceType = "microsoft.operationalinsights/workspaces"
        }
      }
    ]
  })
}



