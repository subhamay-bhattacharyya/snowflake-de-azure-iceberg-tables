# -- infra/platform/tf/outputs.tf (Platform Module)
# ============================================================================
# Platform Module Outputs
# ============================================================================

# ----------------------------------------------------------------------------
# Azure Outputs
# ----------------------------------------------------------------------------
output "resource_group_name" {
  description = "Azure Resource Group name"
  value       = module.azure.resource_group_name
}

output "resource_group_id" {
  description = "Azure Resource Group ID"
  value       = module.azure.resource_group_id
}

output "resource_group_location" {
  description = "Azure Resource Group location"
  value       = module.azure.resource_group_location
}

output "storage_account_name" {
  description = "Azure Storage Account name"
  value       = module.azure.storage_account_name
}

output "storage_account_id" {
  description = "Azure Storage Account ID"
  value       = module.azure.storage_account_id
}

output "storage_account_primary_blob_endpoint" {
  description = "Azure Storage Account primary blob endpoint"
  value       = module.azure.storage_account_primary_blob_endpoint
}

output "storage_account_primary_dfs_endpoint" {
  description = "Azure Storage Account primary DFS endpoint (ADLS Gen2)"
  value       = module.azure.storage_account_primary_dfs_endpoint
}

output "storage_container_name" {
  description = "Azure Storage Container name"
  value       = module.azure.storage_container_name
}

output "storage_container_id" {
  description = "Azure Storage Container ID"
  value       = module.azure.storage_container_id
}

output "table_root_prefixes" {
  description = "Iceberg table root prefixes"
  value       = module.azure.table_root_prefixes
}

# ----------------------------------------------------------------------------
# Snowflake Outputs 
# ----------------------------------------------------------------------------
output "warehouses" {
  description = "Map of warehouse names to their details"
  value       = module.snowflake.warehouses
}

output "databases" {
  description = "Map of databases names to their details"
  value       = module.snowflake.databases
}

output "schemas" {
  description = "Map of databases schemas to their details"
  value       = module.snowflake.schemas
}

output "file_formats" {
  description = "Map of file formats to their details"
  value       = module.snowflake.file_formats
}

output "external_volumes" {
  description = "Map of external volumes to their details"
  value       = module.snowflake.external_volumes
}

output "snowflake_azure_app_name" {
  description = "Snowflake Azure multi-tenant app name"
  value       = local.snowflake_azure_app_name
}

output "snowflake_storage_role_assignment_id" {
  description = "Azure role assignment ID for Snowflake storage access"
  value       = length(azurerm_role_assignment.snowflake_storage) > 0 ? azurerm_role_assignment.snowflake_storage[0].id : null
}

# output "storage_integrations" {
#   description = "Storage integration names"
#   value       = module.snowflake.storage_integrations
# }

# output "stages" {
#   description = "Stage names"
#   value       = module.snowflake.stages
# }


output "storage_integrations" {
  description = "Map of storage integrations to their details"
  value       = module.snowflake.storage_integrations
}

output "stages" {
  description = "Map of stages to their details"
  value       = module.snowflake.stages
}

output "staging_tables" {
  description = "Map of staging tables to their details"
  value       = module.snowflake.tables
}

output "streams" {
  description = "Map of streams to their details"
  value       = module.snowflake.streams
}

output "tasks" {
  description = "Map of tasks to their details"
  value       = module.snowflake.tasks
}

output "snowpipes" {
  description = "Map of snowpipes to their details"
  value       = module.snowflake.snowpipes
}
