# -- infra/azure/tf/outputs.tf (Child Module)
# ============================================================================
# Azure Module Outputs
# ============================================================================

output "resource_group_name" {
  description = "Resource Group name"
  value       = module.resource_group.name
}

output "resource_group_id" {
  description = "Resource Group ID"
  value       = module.resource_group.id
}

output "resource_group_location" {
  description = "Resource Group location"
  value       = module.resource_group.location
}

output "storage_account_name" {
  description = "Storage Account name"
  value       = module.storage_account.name
}

output "storage_account_id" {
  description = "Storage Account ID"
  value       = module.storage_account.id
}

output "storage_account_primary_blob_endpoint" {
  description = "Storage Account primary blob endpoint"
  value       = module.storage_account.primary_blob_endpoint
}

output "storage_account_primary_dfs_endpoint" {
  description = "Storage Account primary DFS endpoint (ADLS Gen2)"
  value       = module.storage_account.primary_dfs_endpoint
}

output "storage_container_name" {
  description = "Storage Container name"
  value       = module.storage_container.name
}

output "storage_container_id" {
  description = "Storage Container ID"
  value       = module.storage_container.id
}

output "table_root_prefixes" {
  description = "List of created Iceberg table root prefixes"
  value       = module.storage_container.prefixes
}

output "snowpipe_queue_url" {
  description = "Azure Storage Queue URL for Snowpipe notifications"
  value       = length(module.storage_queue) > 0 ? "https://${module.storage_account.name}.queue.core.windows.net/${module.storage_queue[0].name}" : null
}
