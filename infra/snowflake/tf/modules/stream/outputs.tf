# -- infra/snowflake/tf/modules/stream/outputs.tf (Child Module)
# Snowflake Stream Outputs

output "name" {
  description = "Stream name"
  value       = snowflake_stream_on_table.this.name
}

output "fully_qualified_name" {
  description = "Fully qualified stream name"
  value       = snowflake_stream_on_table.this.fully_qualified_name
}

output "database" {
  description = "Database name"
  value       = snowflake_stream_on_table.this.database
}

output "schema" {
  description = "Schema name"
  value       = snowflake_stream_on_table.this.schema
}
