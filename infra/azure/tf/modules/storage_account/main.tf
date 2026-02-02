# -- infra/azure/tf/modules/storage_account/main.tf (Child Module)

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_account" "this" {
  name                     = "${var.storage_account.base_name}${random_string.suffix.result}"
  resource_group_name      = var.storage_account.resource_group_name
  location                 = var.storage_account.location
  account_tier             = var.storage_account.account_tier
  account_replication_type = var.storage_account.replication_type
  is_hns_enabled           = var.storage_account.is_hns_enabled
  tags                     = var.storage_account.tags
}
