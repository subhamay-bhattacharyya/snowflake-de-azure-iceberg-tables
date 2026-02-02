# -- infra/azure/tf/modules/storage_container/variables.tf (Child Module)

variable "storage_container" {
  description = "Azure Storage Container configuration"
  type = object({
    name               = string
    storage_account_id = string
    access_type        = string
    prefixes           = list(string)
  })
}
