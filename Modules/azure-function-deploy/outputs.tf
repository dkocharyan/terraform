output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "key_vault_url" {
  value = azurerm_key_vault.kv.vault_uri
}

output "application_insights_name" {
  value = azurerm_application_insights.ai.name
}
