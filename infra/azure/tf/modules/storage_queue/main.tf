# -- infra/azure/tf/modules/storage_queue/main.tf
# ============================================================================
# Storage Queue Module
# ============================================================================

resource "azurerm_storage_queue" "this" {
  name               = var.queue_name
  storage_account_id = var.storage_account_id
}
