# -- infra/platform/tf/main.tf (Platform Module)
# ============================================================================
# Snowflake Lakehouse - Platform Orchestration          ← YOU ARE HERE
# ============================================================================
#
# ┌─────────────────────────────────────────────────────────────┐
# │  PHASE 1: Azure Resources (module.azure)                    │
# ├─────────────────────────────────────────────────────────────┤
# │  1. Resource Group                                          │
# │  2. Storage Account (landing zone for data files)           │
# │  3. Blob Container                                          │
# │     └─► Output: Storage Account URL for External Volume     │
# └─────────────────────────────────────────────────────────────┘
#                             │
#                             ▼
# ┌─────────────────────────────────────────────────────────────┐
# │  PHASE 2: Snowflake Base Resources (module.snowflake)       │
# ├─────────────────────────────────────────────────────────────┤
# │  1. Warehouses (compute resources)                          │
# │  2. Databases & Schemas                                     │
# │  3. External Volume (Azure Blob Storage)                    │
# │  4. Catalog Integration (Iceberg REST catalog)              │
# │  5. Iceberg Tables                                          │
# └─────────────────────────────────────────────────────────────┘
#
# ============================================================================

# ----------------------------------------------------------------------------
# Phase 1: Azure Resources (Resource Group + Storage Account + Container)
# ----------------------------------------------------------------------------
module "azure" {
  source = "../../azure/tf"

  resource_group_config       = local.resource_group_config
  storage_account_config      = local.storage_account_config
  storage_container_config    = local.storage_container_config
  table_root_prefixes         = local.table_root_prefixes
  enable_snowpipe_auto_ingest = true
}

# ----------------------------------------------------------------------------
# Phase 2: Snowflake Base Resources
# ----------------------------------------------------------------------------

# Build external volumes config with dynamic storage URL from Azure module
locals {
  # Build storage_base_url dynamically: azure://<storage_account>.blob.core.windows.net/<container>
  storage_base_url = "azure://${module.azure.storage_account_name}.blob.core.windows.net/${module.azure.storage_container_name}"

  # External Volumes - for Azure Blob Storage (Iceberg tables)
  external_volumes = {
    for ev_key, ev in local.external_volumes_config : ev_key => {
      name                  = var.project_code != "" ? upper("${var.project_code}_${ev.name}") : ev.name
      storage_location_name = ev.storage_location_name
      storage_base_url      = local.storage_base_url
      azure_tenant_id       = var.azure_tenant_id
      comment               = lookup(ev, "comment", "")
    }
  }
}

module "snowflake" {
  source = "../../snowflake/tf"

  warehouse_config                = local.warehouses
  database_config                 = local.databases
  schema_config                   = local.schemas
  file_format_config              = local.file_formats
  external_volume_config          = local.external_volumes
  storage_integration_config      = local.storage_integrations
  stage_config                    = local.stages
  table_config                    = local.staging_tables
  stream_config                   = local.streams
  task_config                     = local.tasks
  notification_integration_config = local.notification_integrations
  snowpipe_config                 = local.snowpipes

  depends_on = [module.azure]
}

# ----------------------------------------------------------------------------
# Phase 3: Grant Snowflake Access to Azure Storage
# ----------------------------------------------------------------------------
# The Snowflake service principal needs "Storage Blob Data Contributor" role
# on the storage account to access Azure Blob Storage.
# ----------------------------------------------------------------------------

locals {
  # Get the first external volume's describe output
  external_volume_keys  = keys(module.snowflake.external_volumes)
  has_external_volume   = length(local.external_volume_keys) > 0
  first_external_volume = local.has_external_volume ? module.snowflake.external_volumes[local.external_volume_keys[0]] : null

  # Extract the describe_output list
  describe_output_list = local.first_external_volume != null ? local.first_external_volume.describe_output : []
  
  # Find the STORAGE_LOCATION entry which contains the JSON with AZURE_MULTI_TENANT_APP_NAME
  storage_location_entries = [
    for item in local.describe_output_list : item
    if can(item.name) && startswith(item.name, "STORAGE_LOCATION_")
  ]
  
  # Parse the JSON value from STORAGE_LOCATION to extract AZURE_MULTI_TENANT_APP_NAME
  storage_location_json = length(local.storage_location_entries) > 0 ? jsondecode(local.storage_location_entries[0].value) : null
  
  snowflake_azure_app_name = local.storage_location_json != null ? lookup(local.storage_location_json, "AZURE_MULTI_TENANT_APP_NAME", "") : ""
  
  # Extract client_id from AZURE_CONSENT_URL (format: ...?client_id=XXXX&...)
  azure_consent_url = local.storage_location_json != null ? lookup(local.storage_location_json, "AZURE_CONSENT_URL", "") : ""
  snowflake_client_id = local.azure_consent_url != "" ? regex("client_id=([^&]+)", local.azure_consent_url)[0] : ""
}

# Look up the Snowflake service principal in Azure AD by application (client) ID
# The client_id is extracted from the AZURE_CONSENT_URL
# Only lookup in Phase 2 (after consent is granted)
data "azuread_service_principal" "snowflake" {
  count     = var.deployment_phase == 2 && local.snowflake_client_id != "" ? 1 : 0
  client_id = local.snowflake_client_id
}

# Grant Snowflake service principal access to the storage account (Phase 2 only)
resource "azurerm_role_assignment" "snowflake_storage" {
  count                = var.deployment_phase == 2 && try(length(data.azuread_service_principal.snowflake), 0) > 0 ? 1 : 0
  scope                = module.azure.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azuread_service_principal.snowflake[0].object_id
}

# Grant Snowflake service principal permission to get user delegation key (Phase 2 only)
resource "azurerm_role_assignment" "snowflake_storage_delegator" {
  count                = var.deployment_phase == 2 && try(length(data.azuread_service_principal.snowflake), 0) > 0 ? 1 : 0
  scope                = module.azure.storage_account_id
  role_definition_name = "Storage Blob Delegator"
  principal_id         = data.azuread_service_principal.snowflake[0].object_id
}

# ----------------------------------------------------------------------------
# Phase 4: Grant Snowflake Notification Integration Access to Azure Queue
# ----------------------------------------------------------------------------
# The notification integration uses a DIFFERENT service principal than the
# storage/external volume integration. We need to look it up separately.
# ----------------------------------------------------------------------------

# Look up the notification integration service principal by client_id
# This requires consent to be granted first via the AZURE_CONSENT_URL (Phase 2 only)
data "azuread_service_principal" "snowpipe" {
  count     = var.deployment_phase == 2 && var.snowpipe_azure_client_id != "" ? 1 : 0
  client_id = var.snowpipe_azure_client_id
}

# Grant notification integration service principal - Storage Queue Data Contributor (Phase 2 only)
resource "azurerm_role_assignment" "snowpipe_queue_contributor" {
  count                = var.deployment_phase == 2 && try(length(data.azuread_service_principal.snowpipe), 0) > 0 ? 1 : 0
  scope                = module.azure.storage_account_id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = data.azuread_service_principal.snowpipe[0].object_id
}

# Grant notification integration service principal - Storage Queue Data Message Processor (Phase 2 only)
resource "azurerm_role_assignment" "snowpipe_queue_processor" {
  count                = var.deployment_phase == 2 && try(length(data.azuread_service_principal.snowpipe), 0) > 0 ? 1 : 0
  scope                = module.azure.storage_account_id
  role_definition_name = "Storage Queue Data Message Processor"
  principal_id         = data.azuread_service_principal.snowpipe[0].object_id
}

# Grant notification integration service principal - Storage Queue Data Reader (Phase 2 only)
resource "azurerm_role_assignment" "snowpipe_queue_reader" {
  count                = var.deployment_phase == 2 && try(length(data.azuread_service_principal.snowpipe), 0) > 0 ? 1 : 0
  scope                = module.azure.storage_account_id
  role_definition_name = "Storage Queue Data Reader"
  principal_id         = data.azuread_service_principal.snowpipe[0].object_id
}
