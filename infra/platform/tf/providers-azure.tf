# -- infra/platform/tf/providers-azure.tf (Platform Module)
# ============================================================================
# Azure Provider Configuration
# ============================================================================
# NOTE: required_providers block is in versions.tf
# ============================================================================

provider "azurerm" {
  features {}

  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_tenant_id
}

# Azure AD provider for service principal lookup
provider "azuread" {
  tenant_id = var.azure_tenant_id
}
