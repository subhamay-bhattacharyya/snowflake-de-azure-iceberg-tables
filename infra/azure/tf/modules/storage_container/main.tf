# -- infra/azure/tf/modules/storage_container/main.tf (Child Module)

resource "azurerm_storage_container" "this" {
  name                  = var.storage_container.name
  storage_account_id    = var.storage_container.storage_account_id
  container_access_type = var.storage_container.access_type
}

# Create table root directories for ADLS Gen2 (HNS enabled)
resource "azurerm_storage_data_lake_gen2_path" "prefix" {
  for_each = toset(var.storage_container.prefixes)

  path               = each.value
  filesystem_name    = azurerm_storage_container.this.name
  storage_account_id = var.storage_container.storage_account_id
  resource           = "directory"
}
