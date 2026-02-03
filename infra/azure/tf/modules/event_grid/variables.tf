# -- infra/azure/tf/modules/event_grid/variables.tf

variable "system_topic_name" {
  description = "Name of the Event Grid system topic"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "source_resource_id" {
  description = "Resource ID of the event source (e.g., storage account)"
  type        = string
}

variable "topic_type" {
  description = "Type of the system topic"
  type        = string
  default     = "Microsoft.Storage.StorageAccounts"
}

variable "subscription_name" {
  description = "Name of the event subscription"
  type        = string
}

variable "storage_account_id" {
  description = "ID of the storage account for queue endpoint"
  type        = string
}

variable "queue_name" {
  description = "Name of the storage queue for event delivery"
  type        = string
}

variable "included_event_types" {
  description = "List of event types to include"
  type        = list(string)
  default     = ["Microsoft.Storage.BlobCreated"]
}

variable "subject_begins_with" {
  description = "Filter for event subjects"
  type        = string
  default     = ""
}
