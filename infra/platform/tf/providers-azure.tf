# -- infra/platform/tf/providers-azure.tf (Platform Module)
# ============================================================================
# Azure Provider Configuration
# ============================================================================
# NOTE: required_providers block is in versions.tf
# Authentication: Uses OIDC via ARM_CLIENT_ID, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
# and ARM_USE_OIDC environment variables set by CI/CD workflow
# ============================================================================

provider "azurerm" {
  features {}

  subscription_id     = var.azure_subscription_id
  tenant_id           = var.azure_tenant_id
  use_oidc            = true
  use_cli             = false
}

# Azure AD provider for service principal lookup
provider "azuread" {
  tenant_id = var.azure_tenant_id
  use_oidc  = true
  use_cli   = false
}
