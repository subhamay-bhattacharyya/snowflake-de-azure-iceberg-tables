# -- infra/azure/tf/modules/resource_group/variables.tf (Child Module)

variable "resource_group" {
  description = "Azure Resource Group configuration"
  type = object({
    name     = string
    location = string
    tags     = map(string)
  })
}
