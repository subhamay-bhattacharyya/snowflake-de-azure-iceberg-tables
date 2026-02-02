# -- infra/azure/tf/modules/storage_queue/outputs.tf

output "name" {
  description = "Name of the storage queue"
  value       = azurerm_storage_queue.this.name
}

output "id" {
  description = "ID of the storage queue"
  value       = azurerm_storage_queue.this.id
}
