# -- infra/azure/tf/modules/event_grid/outputs.tf

output "system_topic_name" {
  description = "Name of the Event Grid system topic"
  value       = azurerm_eventgrid_system_topic.this.name
}

output "system_topic_id" {
  description = "ID of the Event Grid system topic"
  value       = azurerm_eventgrid_system_topic.this.id
}

output "subscription_name" {
  description = "Name of the event subscription"
  value       = azurerm_eventgrid_system_topic_event_subscription.this.name
}

output "subscription_id" {
  description = "ID of the event subscription"
  value       = azurerm_eventgrid_system_topic_event_subscription.this.id
}
