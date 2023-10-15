provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.workload_name}-rg"
  location = var.location
}

resource "azurerm_storage_account" "sa" {
  name                     = "${var.workload_name}-sa"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "results" {
  name                  = "results"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

resource "azurerm_application_insights" "ai" {
  name                = "${var.workload_name}-ai"
  application_type    = "other"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.workload_name}-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  security_rule {
    name                       = "AllowHttpsInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHttpsOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_service_plan" "sp" {
  name                = "${var.workload_name}-app-sp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "P1v2"

}

resource "azurerm_linux_function_app" "fa" {
  name                       = "${var.workload_name}-func"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  service_plan_id            = azurerm_service_plan.sp.id
  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  zip_deploy_file            = "${path.module}/function-app/func.zip"
  app_settings = {
    "AzureWebJobsStorage"    = azurerm_storage_account.sa.primary_connection_string
    "SendGridApiKey"         = var.SendGridApiKey
    "SENDER"                 = var.sender_email
    "RECIPIENT"              = var.recipient_email
    WEBSITE_RUN_FROM_PACKAGE = 1
  }

  site_config {
    always_on                              = true
    linux_fx_version                       = "Python|3.9"
    application_insights_connection_string = azurerm_application_insights.ai.connection_string
    application_insights_key               = azurerm_application_insights.ai.instrumentation_key
    application_stack {
      python_version = "3.9"
    }
  }

}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                            = "${var.workload_name}-kv"
  location                        = var.location
  resource_group_name             = azurerm_resource_group.rg.name
  enabled_for_disk_encryption     = true
  enable_rbac_authorization       = true
  enabled_for_template_deployment = true
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
    ]

    storage_permissions = [
      "Get",
    ]
  }
}

resource "azurerm_key_vault_secret" "connection_string_secret" {
  name         = "ConnectionString"
  value        = azurerm_storage_account.sa.primary_connection_string
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "ai_secret" {
  name         = "AppInsightsKey"
  value        = azurerm_application_insights.ai.instrumentation_key
  key_vault_id = azurerm_key_vault.kv.id
}
