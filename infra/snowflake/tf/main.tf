# -- infra/snowflake/tf/main.tf (Child Module)
# ============================================================================
# Snowflake Lakehouse - Snowflake Resources             ← YOU ARE HERE
# ============================================================================
#
# ┌─────────────────────────────────────────────────────────────┐
# │  1. WAREHOUSES                                              │
# ├─────────────────────────────────────────────────────────────┤
# │  Compute resources for query execution                      │
# │  (LOAD_WH)                                                  │
# └─────────────────────────────────────────────────────────────┘
#
# ============================================================================

# ----------------------------------------------------------------------------
# 1. Warehouses
# ----------------------------------------------------------------------------
resource "snowflake_warehouse" "this" {
  for_each = var.warehouse_config

  name                      = each.value.name
  comment                   = lookup(each.value, "comment", "")
  warehouse_size            = lookup(each.value, "warehouse_size", "X-SMALL")
  auto_resume               = lookup(each.value, "auto_resume", true)
  auto_suspend              = lookup(each.value, "auto_suspend", 60)
  enable_query_acceleration = lookup(each.value, "enable_query_acceleration", false)
  warehouse_type            = lookup(each.value, "warehouse_type", "STANDARD")
  min_cluster_count         = lookup(each.value, "min_cluster_count", 1)
  max_cluster_count         = lookup(each.value, "max_cluster_count", 1)
  scaling_policy            = lookup(each.value, "scaling_policy", "STANDARD")
  initially_suspended       = lookup(each.value, "initially_suspended", true)
}

# ----------------------------------------------------------------------------
# 2. Databases
# ----------------------------------------------------------------------------
resource "snowflake_database" "this" {
  for_each = var.database_config

  name    = each.value.name
  comment = lookup(each.value, "comment", "")
}

# ----------------------------------------------------------------------------
# 2.1 Schemas
# ----------------------------------------------------------------------------
resource "snowflake_schema" "this" {
  for_each = var.schema_config

  database = each.value.database
  name     = each.value.name
  comment  = lookup(each.value, "comment", "")

  depends_on = [snowflake_database.this]
}

# ----------------------------------------------------------------------------
# 3. File Formats
# ----------------------------------------------------------------------------
resource "snowflake_file_format" "this" {
  for_each = var.file_format_config

  name        = each.value.name
  database    = each.value.database
  schema      = each.value.schema
  format_type = each.value.type
  comment     = each.value.comment
  compression = each.value.compression

  # CSV-specific options
  field_delimiter                = each.value.type == "CSV" ? each.value.field_delimiter : null
  record_delimiter               = each.value.type == "CSV" ? each.value.record_delimiter : null
  skip_header                    = each.value.type == "CSV" ? each.value.skip_header : null
  field_optionally_enclosed_by   = each.value.type == "CSV" ? each.value.field_optionally_enclosed_by : null
  trim_space                     = each.value.type == "CSV" ? each.value.trim_space : null
  error_on_column_count_mismatch = each.value.type == "CSV" ? each.value.error_on_column_count_mismatch : null
  escape                         = each.value.type == "CSV" ? each.value.escape : null
  escape_unenclosed_field        = each.value.type == "CSV" ? each.value.escape_unenclosed_field : null
  date_format                    = each.value.type == "CSV" ? each.value.date_format : null
  timestamp_format               = each.value.type == "CSV" ? each.value.timestamp_format : null
  null_if                        = each.value.type == "CSV" ? each.value.null_if : null

  # JSON-specific options
  enable_octal       = each.value.type == "JSON" ? each.value.enable_octal : null
  allow_duplicate    = each.value.type == "JSON" ? each.value.allow_duplicate : null
  strip_outer_array  = each.value.type == "JSON" ? each.value.strip_outer_array : null
  strip_null_values  = each.value.type == "JSON" ? each.value.strip_null_values : null
  ignore_utf8_errors = each.value.type == "JSON" ? each.value.ignore_utf8_errors : null

  depends_on = [snowflake_schema.this]
}

# ----------------------------------------------------------------------------
# 4. External Volume (Azure Blob Storage)
# ----------------------------------------------------------------------------
module "external_volume" {
  source   = "./modules/external_volume"
  for_each = var.external_volume_config

  external_volume = {
    name                  = each.value.name
    storage_location_name = each.value.storage_location_name
    storage_base_url      = each.value.storage_base_url
    azure_tenant_id       = each.value.azure_tenant_id
    comment               = lookup(each.value, "comment", "")
  }

  depends_on = [snowflake_database.this]
}

# ----------------------------------------------------------------------------
# 4. Storage Integrations (Azure)
# ----------------------------------------------------------------------------
resource "snowflake_storage_integration" "this" {
  for_each = var.storage_integration_config

  name    = each.value.name
  type    = "EXTERNAL_STAGE"
  enabled = lookup(each.value, "enabled", true)
  comment = lookup(each.value, "comment", "")

  storage_provider          = each.value.storage_provider
  storage_allowed_locations = each.value.storage_allowed_locations
  storage_blocked_locations = lookup(each.value, "storage_blocked_locations", [])

  # Azure specific
  azure_tenant_id = lookup(each.value, "azure_tenant_id", null)
}

# ----------------------------------------------------------------------------
# 5. Stages
# ----------------------------------------------------------------------------
resource "snowflake_stage" "this" {
  for_each = var.stage_config

  name                = each.value.name
  database            = each.value.database
  schema              = each.value.schema
  url                 = lookup(each.value, "url", null)
  storage_integration = lookup(each.value, "storage_integration", null)
  file_format         = lookup(each.value, "file_format", null)
  comment             = lookup(each.value, "comment", "")

  depends_on = [snowflake_storage_integration.this, snowflake_schema.this, snowflake_file_format.this]
}

# ----------------------------------------------------------------------------
# 6. Tables (Staging Tables)
# ----------------------------------------------------------------------------
resource "snowflake_table" "this" {
  for_each = var.table_config

  database        = each.value.database
  schema          = each.value.schema
  name            = each.value.name
  comment         = lookup(each.value, "comment", "")
  change_tracking = lookup(each.value, "change_tracking", true)

  dynamic "column" {
    for_each = each.value.columns
    content {
      name     = column.value.name
      type     = column.value.type
      nullable = lookup(column.value, "nullable", true)
    }
  }

  depends_on = [snowflake_schema.this]
}

# ----------------------------------------------------------------------------
# 7. Streams (on Staging Tables)
# ----------------------------------------------------------------------------
module "stream" {
  source   = "./modules/stream"
  for_each = var.stream_config

  stream = {
    name              = each.value.name
    database          = each.value.database
    schema            = each.value.schema
    source_table      = each.value.source_table
    comment           = lookup(each.value, "comment", "")
    append_only       = lookup(each.value, "append_only", true)
    show_initial_rows = lookup(each.value, "show_initial_rows", false)
  }

  depends_on = [snowflake_table.this]
}

# ----------------------------------------------------------------------------
# 8. Tasks (Stream to Iceberg)
# ----------------------------------------------------------------------------
module "task" {
  source   = "./modules/task"
  for_each = var.task_config

  task = {
    name             = each.value.name
    database         = each.value.database
    schema           = each.value.schema
    warehouse        = each.value.warehouse
    schedule_minutes = each.value.schedule_minutes
    sql_statement    = each.value.sql_statement
    comment          = lookup(each.value, "comment", "")
    when_condition   = lookup(each.value, "when_condition", null)
    started          = lookup(each.value, "started", false)
  }

  depends_on = [module.stream]
}

# ----------------------------------------------------------------------------
# 9. Notification Integration (Azure Storage Queue for Snowpipe)
# ----------------------------------------------------------------------------
resource "snowflake_notification_integration" "this" {
  for_each = var.notification_integration_config

  name    = each.value.name
  enabled = lookup(each.value, "enabled", true)
  comment = lookup(each.value, "comment", "")

  notification_provider           = "AZURE_STORAGE_QUEUE"
  azure_storage_queue_primary_uri = each.value.azure_storage_queue_primary_uri
  azure_tenant_id                 = each.value.azure_tenant_id
}

# ----------------------------------------------------------------------------
# 10. Snowpipes (Auto-ingest to Staging Tables)
# ----------------------------------------------------------------------------
resource "snowflake_pipe" "this" {
  for_each = var.snowpipe_config

  name           = each.value.name
  database       = each.value.database
  schema         = each.value.schema
  copy_statement = each.value.copy_statement
  auto_ingest    = lookup(each.value, "auto_ingest", true)
  integration    = lookup(each.value, "integration", null)
  comment        = lookup(each.value, "comment", "")

  depends_on = [snowflake_stage.this, snowflake_table.this, snowflake_notification_integration.this]
}
