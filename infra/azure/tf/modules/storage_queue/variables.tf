# -- infra/azure/tf/modules/storage_queue/variables.tf

variable "queue_name" {
  description = "Name of the storage queue"
  type        = string
}

variable "storage_account_id" {
  description = "ID of the storage account"
  type        = string
}
