# -- infra/platform/tf/providers-azure.tf (Platform Module)
# ============================================================================
# Azure Provider Configuration
# ============================================================================
# NOTE: required_providers block is in versions.tf
# Authentication: Relies on ARM_* environment variables set by CI/CD workflow:
#   - ARM_CLIENT_ID
#   - ARM_TENANT_ID  
#   - ARM_SUBSCRIPTION_ID
#   - ARM_USE_OIDC=true (for OIDC auth)
# ============================================================================

provider "azurerm" {
  features {}
  subscription_id                 = var.azure_subscription_id
  resource_provider_registrations = "none"
}

# Azure AD provider for service principal lookup
provider "azuread" {
}
