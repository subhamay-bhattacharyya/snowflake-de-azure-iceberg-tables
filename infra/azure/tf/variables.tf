# -- infra/azure/tf/variables.tf (Child Module)
# ============================================================================
# Azure Module Variables
# ============================================================================

variable "resource_group_config" {
  description = "Resource Group configuration"
  type = object({
    name     = string
    location = string
    tags     = map(string)
  })
}

variable "storage_account_config" {
  description = "Storage Account configuration"
  type = object({
    base_name        = string
    account_tier     = string
    replication_type = string
    is_hns_enabled   = bool
  })
}

variable "storage_container_config" {
  description = "Storage Container configuration"
  type = object({
    name        = string
    access_type = string
  })
}

variable "table_root_prefixes" {
  description = "List of Iceberg table root prefixes (e.g., iceberg/sales/orders)"
  type        = list(string)
  default     = []
}

variable "enable_snowpipe_auto_ingest" {
  description = "Enable Azure Event Grid and Storage Queue for Snowpipe auto-ingest"
  type        = bool
  default     = false
}
