# -- infra/platform/tf/locals.tf (Platform Module)
# ============================================================================
# Local Values
# ============================================================================

locals {
  # Parse config from JSON files (relative to module path)
  azure_config_file     = jsondecode(file("${path.module}/${var.azure_config_path}"))
  snowflake_config_file = jsondecode(file("${path.module}/${var.snowflake_config_path}"))

  # Extract nested sections
  azure_config     = local.azure_config_file.azure
  snowflake_config = local.snowflake_config_file

  # ============================================================================
  # Azure Configuration
  # ============================================================================

  # Resource Group Configuration
  resource_group_config = {
    name     = "${var.project_code}-${local.azure_config.resource_group.name}"
    location = local.azure_config.resource_group.location
    tags = merge(local.azure_config.resource_group.tags, {
      project     = var.project_code
      environment = var.environment
    })
  }

  # Storage Account Configuration
  storage_account_config = {
    base_name        = local.azure_config.storage_account.base_name
    account_tier     = local.azure_config.storage_account.account_tier
    replication_type = local.azure_config.storage_account.replication_type
    is_hns_enabled   = local.azure_config.storage_account.is_hns_enabled
  }

  # Storage Container Configuration
  storage_container_config = {
    name        = local.azure_config.storage_container.name
    access_type = local.azure_config.storage_container.access_type
  }

  # Table Root Prefixes (iceberg/<db>/<table>/)
  table_root_prefixes = local.azure_config.table_root_prefixes

  # ============================================================================
  # Snowflake Configuration
  # ============================================================================

  # Warehouses - add optional prefix to names
  warehouses = {
    for key, wh in local.snowflake_config.warehouses : key => merge(wh, {
      name = var.project_code != "" ? upper("${var.project_code}_${wh.name}") : wh.name
    })
  }

  # Databases - extract only database-level attributes with optional prefix
  databases = {
    for key, db in local.snowflake_config.databases : key => {
      name    = var.project_code != "" ? upper("${var.project_code}_${db.name}") : db.name
      comment = lookup(db, "comment", "")
    }
  }

  # Schemas - flatten from all databases into a map
  schemas = {
    for item in flatten([
      for db_key, db in local.snowflake_config.databases : [
        for schema in lookup(db, "schemas", []) : {
          key      = "${db_key}_${lower(schema.name)}"
          database = var.project_code != "" ? upper("${var.project_code}_${db.name}") : db.name
          name     = schema.name
          comment  = lookup(schema, "comment", "")
        }
      ]
    ]) : item.key => item
  }

  # File Formats - flatten from all databases into a map with normalized structure
  file_formats = {
    for item in flatten([
      for db_key, db in local.snowflake_config.databases : [
        for ff_key, ff in lookup(db, "file_formats", {}) : {
          key         = "${db_key}_${ff_key}"
          name        = ff.name
          type        = ff.type
          database    = var.project_code != "" ? upper("${var.project_code}_${db.name}") : db.name
          schema      = "UTIL"
          comment     = lookup(ff, "comment", "")
          compression = lookup(ff, "compression", "AUTO")
          # CSV options
          field_delimiter                = lookup(ff, "field_delimiter", ",")
          record_delimiter               = lookup(ff, "record_delimiter", "\n")
          skip_header                    = lookup(ff, "skip_header", 0)
          field_optionally_enclosed_by   = lookup(ff, "field_optionally_enclosed_by", null)
          trim_space                     = lookup(ff, "trim_space", false)
          error_on_column_count_mismatch = lookup(ff, "error_on_column_count_mismatch", true)
          escape                         = lookup(ff, "escape", null)
          escape_unenclosed_field        = lookup(ff, "escape_unenclosed_field", null)
          date_format                    = lookup(ff, "date_format", "AUTO")
          timestamp_format               = lookup(ff, "timestamp_format", "AUTO")
          null_if                        = lookup(ff, "null_if", [])
          # JSON options
          enable_octal       = lookup(ff, "enable_octal", false)
          allow_duplicate    = lookup(ff, "allow_duplicate", false)
          strip_outer_array  = lookup(ff, "strip_outer_array", false)
          strip_null_values  = lookup(ff, "strip_null_values", false)
          ignore_utf8_errors = lookup(ff, "ignore_utf8_errors", false)
        }
      ]
    ]) : item.key => item
  }

  # External Volumes - built dynamically in main.tf using Azure module outputs
  external_volumes_config = lookup(local.snowflake_config, "external_volumes", {})

  # ============================================================================
  # Azure Storage Integration for Snowpipe
  # ============================================================================
  
  # Storage Integrations - for Azure Blob Storage access
  storage_integrations = {
    azure_storage = {
      name                      = var.project_code != "" ? upper("${var.project_code}_AZURE_STORAGE_INT") : "AZURE_STORAGE_INT"
      storage_provider          = "AZURE"
      azure_tenant_id           = var.azure_tenant_id
      storage_allowed_locations = ["azure://${module.azure.storage_account_name}.blob.core.windows.net/${module.azure.storage_container_name}/"]
      enabled                   = true
      comment                   = "Azure Blob Storage integration for Snowpipe"
    }
  }

  # Stages - Azure external stage for data ingestion
  stages = {
    azure_csv_stage = {
      name                = var.project_code != "" ? upper("${var.project_code}_AZURE_CSV_STAGE") : "AZURE_CSV_STAGE"
      database            = var.project_code != "" ? upper("${var.project_code}_ICEBERG_DB") : "ICEBERG_DB"
      schema              = "UTIL"
      url                 = "azure://${module.azure.storage_account_name}.blob.core.windows.net/${module.azure.storage_container_name}/iceberg/raw-data/csv/"
      storage_integration = var.project_code != "" ? upper("${var.project_code}_AZURE_STORAGE_INT") : "AZURE_STORAGE_INT"
      file_format         = "FORMAT_NAME = '${var.project_code != "" ? upper("${var.project_code}_ICEBERG_DB") : "ICEBERG_DB"}.UTIL.CSV_FILE_FORMAT'"
      comment             = "External stage for Azure Blob CSV data ingestion"
    }
  }

  # ============================================================================
  # Staging Tables, Streams, Tasks, and Snowpipes
  # ============================================================================

  # Staging Tables - regular Snowflake tables for Snowpipe ingestion
  staging_tables = {
    orders_staging = {
      name     = var.project_code != "" ? upper("${var.project_code}_ORDERS_STAGING") : "ORDERS_STAGING"
      database = var.project_code != "" ? upper("${var.project_code}_ICEBERG_DB") : "ICEBERG_DB"
      schema   = "RAW_DATA"
      comment  = "Staging table for orders data - Snowpipe loads here"
      columns = [
        { name = "ORDER_ID", type = "STRING" },
        { name = "CUSTOMER_ID", type = "STRING" },
        { name = "ORDER_DATE", type = "DATE" },
        { name = "PRODUCT", type = "STRING" },
        { name = "QUANTITY", type = "INT" },
        { name = "UNIT_PRICE", type = "DECIMAL(10,2)" },
        { name = "REGION", type = "STRING" },
        { name = "SOURCE_FILE", type = "STRING" },
        { name = "LOAD_TIMESTAMP", type = "TIMESTAMP_NTZ" }
      ]
    }
  }

  # Streams - capture changes on staging tables
  streams = {
    orders_stream = {
      name         = var.project_code != "" ? upper("${var.project_code}_ORDERS_STREAM") : "ORDERS_STREAM"
      database     = var.project_code != "" ? upper("${var.project_code}_ICEBERG_DB") : "ICEBERG_DB"
      schema       = "RAW_DATA"
      source_table = var.project_code != "" ? upper("${var.project_code}_ORDERS_STAGING") : "ORDERS_STAGING"
      comment      = "Stream on orders staging table for CDC to Iceberg"
      append_only  = true
    }
  }

  # Tasks - move data from stream to Iceberg table
  tasks = {
    orders_to_iceberg = {
      name             = var.project_code != "" ? upper("${var.project_code}_ORDERS_TO_ICEBERG") : "ORDERS_TO_ICEBERG"
      database         = var.project_code != "" ? upper("${var.project_code}_ICEBERG_DB") : "ICEBERG_DB"
      schema           = "RAW_DATA"
      warehouse        = var.project_code != "" ? upper("${var.project_code}_LOAD_WH") : "LOAD_WH"
      schedule_minutes = 1
      when_condition   = "SYSTEM$STREAM_HAS_DATA('${var.project_code != "" ? upper("${var.project_code}_ICEBERG_DB") : "ICEBERG_DB"}.RAW_DATA.${var.project_code != "" ? upper("${var.project_code}_ORDERS_STREAM") : "ORDERS_STREAM"}')"
      sql_statement    = <<-SQL
        INSERT INTO ${var.project_code != "" ? upper("${var.project_code}_ICEBERG_DB") : "ICEBERG_DB"}.RAW_DATA.ORDERS_ICEBERG 
        (ORDER_ID, CUSTOMER_ID, ORDER_DATE, PRODUCT, QUANTITY, UNIT_PRICE, REGION)
        SELECT ORDER_ID, CUSTOMER_ID, ORDER_DATE, PRODUCT, QUANTITY, UNIT_PRICE, REGION
        FROM ${var.project_code != "" ? upper("${var.project_code}_ICEBERG_DB") : "ICEBERG_DB"}.RAW_DATA.${var.project_code != "" ? upper("${var.project_code}_ORDERS_STREAM") : "ORDERS_STREAM"}
      SQL
      comment          = "Task to move orders data from staging stream to Iceberg table"
      started          = false  # Set to true after Iceberg table is created
    }
  }

  # Snowpipes - auto-ingest from Azure Blob to staging tables
  # NOTE: Auto-ingest disabled due to Azure queue permission issues
  # Use ALTER PIPE ... REFRESH to manually trigger loads
  snowpipes = {
    orders_pipe = {
      name        = var.project_code != "" ? upper("${var.project_code}_ORDERS_PIPE") : "ORDERS_PIPE"
      database    = var.project_code != "" ? upper("${var.project_code}_ICEBERG_DB") : "ICEBERG_DB"
      schema      = "RAW_DATA"
      auto_ingest = false
      integration = null
      copy_statement = <<-SQL
        COPY INTO ${var.project_code != "" ? upper("${var.project_code}_ICEBERG_DB") : "ICEBERG_DB"}.RAW_DATA.${var.project_code != "" ? upper("${var.project_code}_ORDERS_STAGING") : "ORDERS_STAGING"}
        (ORDER_ID, CUSTOMER_ID, ORDER_DATE, PRODUCT, QUANTITY, UNIT_PRICE, REGION, SOURCE_FILE, LOAD_TIMESTAMP)
        FROM (
          SELECT $1, $2, $3, $4, $5, $6, $7, METADATA$FILENAME, CURRENT_TIMESTAMP()
          FROM @${var.project_code != "" ? upper("${var.project_code}_ICEBERG_DB") : "ICEBERG_DB"}.UTIL.${var.project_code != "" ? upper("${var.project_code}_AZURE_CSV_STAGE") : "AZURE_CSV_STAGE"}
        )
        FILE_FORMAT = (FORMAT_NAME = '${var.project_code != "" ? upper("${var.project_code}_ICEBERG_DB") : "ICEBERG_DB"}.UTIL.CSV_FILE_FORMAT')
        PATTERN = '.*orders.*\\.csv'
      SQL
      comment     = "Snowpipe for orders CSV data ingestion from Azure Blob"
    }
  }

  # Notification integrations - Azure Storage Queue for Snowpipe auto-ingest
  notification_integrations = {
    azure_snowpipe = {
      name                            = var.project_code != "" ? upper("${var.project_code}_AZURE_SNOWPIPE_INT") : "AZURE_SNOWPIPE_INT"
      azure_storage_queue_primary_uri = module.azure.snowpipe_queue_url
      azure_tenant_id                 = var.azure_tenant_id
      enabled                         = true
      comment                         = "Azure Storage Queue notification integration for Snowpipe"
    }
  }
}
