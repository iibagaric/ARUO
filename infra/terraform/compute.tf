resource "azurerm_public_ip" "jump" {
  name                = "pip-${local.name}-jump"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

resource "azurerm_network_interface" "jump" {
  name                = "nic-${local.name}-jump"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.jump.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jump.id
  }
}

resource "azurerm_windows_virtual_machine" "jump" {
  name                      = "vm${local.suffix}jump"
  resource_group_name       = data.azurerm_resource_group.main.name
  location                  = var.location
  size                      = var.jump_vm_size
  admin_username            = var.jump_admin_username
  admin_password            = var.jump_admin_password
  network_interface_ids     = [azurerm_network_interface.jump.id]
  patch_mode                = "AutomaticByPlatform"
  provision_vm_agent        = true
  automatic_updates_enabled = true
  tags                      = local.common_tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
}

resource "azurerm_storage_account" "function" {
  name                            = "func${replace(local.name, "-", "")}"
  resource_group_name             = data.azurerm_resource_group.main.name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags                            = local.common_tags
}

resource "azurerm_service_plan" "function" {
  name                = "asp-${local.name}-function"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "B1"
  tags                = local.common_tags
}

resource "azurerm_linux_function_app" "main" {
  name                          = "func-${local.name}"
  resource_group_name           = data.azurerm_resource_group.main.name
  location                      = var.location
  service_plan_id               = azurerm_service_plan.function.id
  storage_account_name          = azurerm_storage_account.function.name
  storage_account_access_key    = azurerm_storage_account.function.primary_access_key
  public_network_access_enabled = var.bootstrap_public_access
  virtual_network_subnet_id     = azurerm_subnet.function_integration.id
  tags                          = local.common_tags

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on              = true
    ftps_state             = "Disabled"
    minimum_tls_version    = "1.2"
    vnet_route_all_enabled = true

    application_stack {
      node_version = "24"
    }
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "node"
    WEBSITE_RUN_FROM_PACKAGE = "1"
  }
}

resource "azurerm_private_endpoint" "function" {
  name                = "pe-${local.name}-function"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-function"
    private_connection_resource_id = azurerm_linux_function_app.main.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.web.id]
  }
}

resource "azurerm_public_ip" "app_gateway" {
  name                = "pip-${local.name}-appgw"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

resource "azurerm_application_gateway" "main" {
  name                = "agw-${local.name}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.common_tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app_gateway.id]
  }

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "appgw-ipconfig"
    subnet_id = azurerm_subnet.app_gateway.id
  }

  frontend_port {
    name = "port-443"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "public-frontend"
    public_ip_address_id = azurerm_public_ip.app_gateway.id
  }

  ssl_certificate {
    name                = "cert-from-key-vault"
    key_vault_secret_id = azurerm_key_vault_certificate.app_gateway.secret_id
  }

  backend_address_pool {
    name  = "function-backend"
    fqdns = [azurerm_linux_function_app.main.default_hostname]
  }

  backend_http_settings {
    name                                = "function-https"
    cookie_based_affinity               = "Disabled"
    port                                = 443
    protocol                            = "Https"
    request_timeout                     = 30
    host_name                           = azurerm_linux_function_app.main.default_hostname
    pick_host_name_from_backend_address = false
  }

  http_listener {
    name                           = "https-listener"
    frontend_ip_configuration_name = "public-frontend"
    frontend_port_name             = "port-443"
    protocol                       = "Https"
    ssl_certificate_name           = "cert-from-key-vault"
  }

  request_routing_rule {
    name               = "path-routing"
    rule_type          = "PathBasedRouting"
    http_listener_name = "https-listener"
    url_path_map_name  = "main-path-map"
    priority           = 100
  }

  url_path_map {
    name                               = "main-path-map"
    default_backend_address_pool_name  = "function-backend"
    default_backend_http_settings_name = "function-https"

    path_rule {
      name                       = "functionap"
      paths                      = ["/functionap", "/functionap/*"]
      backend_address_pool_name  = "function-backend"
      backend_http_settings_name = "function-https"
    }
  }

  depends_on = [
    azurerm_role_assignment.appgw_key_vault_secrets,
    azurerm_role_assignment.appgw_key_vault_certificates
  ]
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                      = "aks-${local.name}"
  location                  = var.location
  resource_group_name       = data.azurerm_resource_group.main.name
  dns_prefix                = "aks-${local.name}"
  private_cluster_enabled   = true
  private_dns_zone_id       = azurerm_private_dns_zone.aks.id
  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  automatic_upgrade_channel = "patch"
  node_os_upgrade_channel   = "NodeImage"
  sku_tier                  = "Standard"
  tags                      = local.common_tags

  default_node_pool {
    name                         = "system"
    vm_size                      = var.aks_node_vm_size
    node_count                   = 1
    vnet_subnet_id               = azurerm_subnet.aks.id
    temporary_name_for_rotation  = "tempsys"
    only_critical_addons_enabled = false
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_control_plane.id]
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = "10.30.0.0/16"
    dns_service_ip    = "10.30.0.10"
  }

  ingress_application_gateway {
    gateway_id = azurerm_application_gateway.main.id
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    utc_offset  = "+00:00"
    start_time  = "02:00"
  }

  depends_on = [
    azurerm_role_assignment.aks_private_dns,
    azurerm_role_assignment.aks_network
  ]
}

resource "azurerm_role_assignment" "acr_pull_kubelet" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

resource "azurerm_role_assignment" "agic_appgw_contributor" {
  scope                = azurerm_application_gateway.main.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
}

resource "azurerm_federated_identity_credential" "workload" {
  name                = "fic-${local.name}-sample-workload"
  resource_group_name = data.azurerm_resource_group.main.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.workload.id
  subject             = "system:serviceaccount:sample:sample-workload-sa"
}



resource "azurerm_role_assignment" "agic_appgw_identity_operator" {
  scope                = azurerm_user_assigned_identity.app_gateway.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
}

resource "azurerm_role_assignment" "agic_network_contributor" {
  scope                = azurerm_virtual_network.app.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
}
