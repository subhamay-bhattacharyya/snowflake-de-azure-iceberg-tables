# -- infra/azure/tf/modules/storage_container/outputs.tf (Child Module)

output "name" {
  description = "Storage Container name"
  value       = azurerm_storage_container.this.name
}

output "id" {
  description = "Storage Container ID"
  value       = azurerm_storage_container.this.id
}

output "prefixes" {
  description = "List of created table root directories"
  value       = [for path in azurerm_storage_data_lake_gen2_path.prefix : path.path]
}
