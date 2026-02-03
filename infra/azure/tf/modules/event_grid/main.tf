# -- infra/azure/tf/modules/event_grid/main.tf
# ============================================================================
# Event Grid Module
# ============================================================================

resource "azurerm_eventgrid_system_topic" "this" {
  name                = var.system_topic_name
  resource_group_name = var.resource_group_name
  location            = var.location
  source_resource_id  = var.source_resource_id
  topic_type          = var.topic_type
}

resource "azurerm_eventgrid_system_topic_event_subscription" "this" {
  name                = var.subscription_name
  system_topic        = azurerm_eventgrid_system_topic.this.name
  resource_group_name = var.resource_group_name

  storage_queue_endpoint {
    storage_account_id = var.storage_account_id
    queue_name         = var.queue_name
  }

  included_event_types = var.included_event_types

  subject_filter {
    subject_begins_with = var.subject_begins_with
  }

  depends_on = [azurerm_eventgrid_system_topic.this]
}
