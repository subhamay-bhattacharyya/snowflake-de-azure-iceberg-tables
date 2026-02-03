# -- infra/snowflake/tf/modules/stream/versions.tf (Child Module)

terraform {
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = ">= 1.0.0"
    }
  }
}
