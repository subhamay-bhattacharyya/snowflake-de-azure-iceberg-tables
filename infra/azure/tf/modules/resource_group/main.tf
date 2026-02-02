# -- infra/azure/tf/modules/resource_group/main.tf (Child Module)

resource "azurerm_resource_group" "this" {
  name     = var.resource_group.name
  location = var.resource_group.location
  tags     = var.resource_group.tags
}
