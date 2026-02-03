# -- infra/platform/tf/variables.tf (Platform Module)
# ============================================================================
# Platform Module Variables
# ============================================================================

variable "environment" {
  description = "Environment name (devl, test, prod)"
  type        = string
  default     = "devl"

  validation {
    condition     = contains(["devl", "test", "prod"], var.environment)
    error_message = "Environment must be devl, test, or prod."
  }
}

variable "project_code" {
  description = "Project code prefix for resource naming (e.g., snw-lkh)"
  type        = string
  default     = "snw"
}

# ============================================================================
# Azure Provider Variables
# ============================================================================

variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "azure_tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "azure_client_id" {
  description = "Azure Client ID for OIDC authentication"
  type        = string
  default     = ""
}

# ============================================================================
# Snowflake Provider Variables
# ============================================================================

variable "snowflake_organization_name" {
  description = "Snowflake organization name"
  type        = string
  default     = ""
}

variable "snowflake_account_name" {
  description = "Snowflake account name"
  type        = string
  default     = ""
}

variable "snowflake_user" {
  description = "Snowflake user for Terraform operations"
  type        = string
  default     = ""
}

variable "snowflake_role" {
  description = "Snowflake role for Terraform operations"
  type        = string
  default     = "SYSADMIN"
}

variable "snowflake_warehouse" {
  description = "Snowflake warehouse for Terraform operations"
  type        = string
  default     = "COMPUTE_WH"
}

# Note: For CI/CD, set SNOWFLAKE_PRIVATE_KEY environment variable directly
# The provider will pick it up automatically

# ============================================================================
# Configuration File Paths
# ============================================================================

variable "azure_config_path" {
  description = "Path to Azure config JSON file (relative to module)"
  type        = string
  default     = "../../../input-jsons/azure/config.json"
}

variable "snowflake_config_path" {
  description = "Path to Snowflake config JSON file (relative to module)"
  type        = string
  default     = "../../../input-jsons/snowflake/config.json"
}

# ============================================================================
# Snowpipe Notification Integration Variables
# ============================================================================

variable "snowpipe_azure_client_id" {
  description = "Azure client_id for Snowpipe notification integration (extracted from AZURE_CONSENT_URL)"
  type        = string
  default     = ""
}

# ============================================================================
# Deployment Phase Control
# ============================================================================

variable "deployment_phase" {
  description = "Deployment phase: 1 = base infrastructure (before consent), 2 = full deployment (after consent)"
  type        = number
  default     = 1

  validation {
    condition     = contains([1, 2], var.deployment_phase)
    error_message = "deployment_phase must be 1 or 2."
  }
}
