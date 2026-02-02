# -- infra/platform/tf/terraform.tfvars (Platform Module)
# ============================================================================
# Terraform Variable Values
# ============================================================================

# ----------------------------------------------------------------------------
# Azure Provider Configuration
# ----------------------------------------------------------------------------
azure_subscription_id = "8ea2d3cf-0884-4fea-ab51-9b88f5644937" # Set your Azure subscription ID
azure_tenant_id       = "1e79bc38-cdfb-4573-aa35-2e2b434315fc" # Set your Azure tenant ID

# ----------------------------------------------------------------------------
# Snowflake Provider Configuration
# ----------------------------------------------------------------------------
snowflake_organization_name = "AGXUOKJ"
snowflake_account_name      = "JKC15404"
snowflake_user              = "GH_ACTIONS_USER"
snowflake_role              = "ACCOUNTADMIN"
snowflake_warehouse         = "UTIL_WH"
# For CI/CD: Set SNOWFLAKE_PRIVATE_KEY environment variable with key content
azure_config_path     = "../../../input-jsons/azure/config.json"
snowflake_config_path = "../../../input-jsons/snowflake/config.json"
# ----------------------------------------------------------------------------
# Project Configuration
# ----------------------------------------------------------------------------
project_code = "demo"

# Snowpipe notification integration app name (from DESC NOTIFICATION INTEGRATION)
snowpipe_azure_app_name  = "n5vfd8snowflakepacint_1770058162569"
snowpipe_azure_client_id = "0fdfefaf-75cc-4f45-b886-faaeeb8d4e20"


# Deployment phase: 1 = base infrastructure, 2 = full with role assignments
deployment_phase = 1
