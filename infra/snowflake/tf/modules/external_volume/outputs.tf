# -- infra/snowflake/tf/modules/external_volume/outputs.tf (Child Module)

output "name" {
  description = "External Volume name"
  value       = snowflake_external_volume.this.name
}

output "id" {
  description = "External Volume ID"
  value       = snowflake_external_volume.this.id
}

output "describe_output" {
  description = "External Volume describe output (contains Azure consent URL and service principal)"
  value       = snowflake_external_volume.this.describe_output
}
