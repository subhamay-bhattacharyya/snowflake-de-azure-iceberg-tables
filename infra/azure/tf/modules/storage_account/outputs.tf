# -- infra/azure/tf/modules/storage_account/outputs.tf (Child Module)

output "name" {
  description = "Storage Account name"
  value       = azurerm_storage_account.this.name
}

output "id" {
  description = "Storage Account ID"
  value       = azurerm_storage_account.this.id
}

output "primary_blob_endpoint" {
  description = "Primary Blob endpoint URL"
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "primary_dfs_endpoint" {
  description = "Primary DFS endpoint URL (for ADLS Gen2)"
  value       = azurerm_storage_account.this.primary_dfs_endpoint
}

output "primary_access_key" {
  description = "Primary access key"
  value       = azurerm_storage_account.this.primary_access_key
  sensitive   = true
}
