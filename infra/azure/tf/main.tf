# -- infra/azure/tf/main.tf (Child Module)
# ============================================================================
# Azure Infrastructure - Azure Resources                ← YOU ARE HERE
# ============================================================================
#
# ┌─────────────────────────────────────────────────────────────┐
# │  1. RESOURCE GROUP                                          │
# ├─────────────────────────────────────────────────────────────┤
# │  Logical container for Azure resources                      │
# │  (Groups storage, networking, and access resources)         │
# └─────────────────────────────────────────────────────────────┘
#                             │
#                             ▼
# ┌─────────────────────────────────────────────────────────────┐
# │  2. STORAGE ACCOUNT                                         │
# ├─────────────────────────────────────────────────────────────┤
# │  Azure Blob Storage for Iceberg data and metadata           │
# │  (Hierarchical namespace enabled for ADLS Gen2)             │
# └─────────────────────────────────────────────────────────────┘
#                             │
#                             ▼
# ┌─────────────────────────────────────────────────────────────┐
# │  3. BLOB CONTAINER + TABLE ROOT PREFIXES                    │
# ├─────────────────────────────────────────────────────────────┤
# │  Container for Iceberg table data files                     │
# │  Prefixes: iceberg/<db>/<table>/                            │
# │  Output: Container URL for Snowflake External Volume        │
# └─────────────────────────────────────────────────────────────┘
#
# ============================================================================

# ----------------------------------------------------------------------------
# 1. Resource Group
# ----------------------------------------------------------------------------
module "resource_group" {
  source = "./modules/resource_group"

  resource_group = var.resource_group_config
}

# ----------------------------------------------------------------------------
# 2. Storage Account
# ----------------------------------------------------------------------------
module "storage_account" {
  source = "./modules/storage_account"

  storage_account = {
    base_name           = var.storage_account_config.base_name
    resource_group_name = module.resource_group.name
    location            = module.resource_group.location
    account_tier        = var.storage_account_config.account_tier
    replication_type    = var.storage_account_config.replication_type
    is_hns_enabled      = var.storage_account_config.is_hns_enabled
    tags                = var.resource_group_config.tags
  }

  depends_on = [module.resource_group]
}

# ----------------------------------------------------------------------------
# 3. Storage Container + Table Root Prefixes
# ----------------------------------------------------------------------------
module "storage_container" {
  source = "./modules/storage_container"

  storage_container = {
    name               = var.storage_container_config.name
    storage_account_id = module.storage_account.id
    access_type        = var.storage_container_config.access_type
    prefixes           = var.table_root_prefixes
  }

  depends_on = [module.storage_account]
}

# ----------------------------------------------------------------------------
# 4. Storage Queue (for Snowpipe auto-ingest notifications)
# ----------------------------------------------------------------------------
module "storage_queue" {
  source = "./modules/storage_queue"
  count  = var.enable_snowpipe_auto_ingest ? 1 : 0

  queue_name         = "snowpipe-notifications"
  storage_account_id = module.storage_account.id

  depends_on = [module.storage_account]
}

# ----------------------------------------------------------------------------
# 5. Event Grid (System Topic + Subscription for blob events)
# ----------------------------------------------------------------------------
module "event_grid" {
  source = "./modules/event_grid"
  count  = var.enable_snowpipe_auto_ingest ? 1 : 0

  system_topic_name    = "${module.storage_account.name}-events"
  resource_group_name  = module.resource_group.name
  location             = module.resource_group.location
  source_resource_id   = module.storage_account.id
  subscription_name    = "snowpipe-blob-events"
  storage_account_id   = module.storage_account.id
  queue_name           = module.storage_queue[0].name
  included_event_types = ["Microsoft.Storage.BlobCreated"]
  subject_begins_with  = "/blobServices/default/containers/${module.storage_container.name}/blobs/iceberg/raw-data/"

  depends_on = [module.storage_queue]
}
