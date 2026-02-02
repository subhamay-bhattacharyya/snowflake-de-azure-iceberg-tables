# -- infra/snowflake/tf/modules/external_volume/variables.tf (Child Module)

variable "external_volume" {
  description = "Snowflake External Volume configuration for Azure"
  type = object({
    name                  = string
    storage_location_name = string
    storage_base_url      = string
    azure_tenant_id       = string
    comment               = string
  })
}
