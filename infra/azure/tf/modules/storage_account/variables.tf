# -- infra/azure/tf/modules/storage_account/variables.tf (Child Module)

variable "storage_account" {
  description = "Azure Storage Account configuration"
  type = object({
    base_name           = string
    resource_group_name = string
    location            = string
    account_tier        = string
    replication_type    = string
    is_hns_enabled      = bool
    tags                = map(string)
  })
}
