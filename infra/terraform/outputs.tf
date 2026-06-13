output "resource_group_name" {
  value = data.azurerm_resource_group.main.name
}

output "location" {
  value = var.location
}

output "jump_public_ip" {
  value = azurerm_public_ip.jump.ip_address
}

output "application_gateway_public_ip" {
  value = azurerm_public_ip.app_gateway.ip_address
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "acr_name" {
  value = azurerm_container_registry.main.name
}

output "acr_login_server" {
  value = azurerm_container_registry.main.login_server
}

output "function_app_name" {
  value = azurerm_linux_function_app.main.name
}

output "key_vault_name" {
  value = azurerm_key_vault.main.name
}

output "workload_identity_client_id" {
  value = azurerm_user_assigned_identity.workload.client_id
}

output "storage_account_name" {
  value = azurerm_storage_account.main.name
}

output "postgres_fqdn" {
  value = azurerm_postgresql_flexible_server.main.fqdn
}

output "log_analytics_workspace_name" {
  value = azurerm_log_analytics_workspace.main.name
}


