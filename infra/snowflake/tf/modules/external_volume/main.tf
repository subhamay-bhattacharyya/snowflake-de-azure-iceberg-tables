# -- infra/snowflake/tf/modules/external_volume/main.tf (Child Module)
# Creates Snowflake External Volume for Azure Blob Storage

resource "snowflake_external_volume" "this" {
  name = var.external_volume.name

  storage_location {
    storage_location_name = var.external_volume.storage_location_name
    storage_provider      = "AZURE"
    storage_base_url      = var.external_volume.storage_base_url
    azure_tenant_id       = var.external_volume.azure_tenant_id
  }

  comment = var.external_volume.comment
}
