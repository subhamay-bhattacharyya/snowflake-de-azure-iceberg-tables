# -- infra/snowflake/tf/modules/task/outputs.tf (Child Module)
# Snowflake Task Outputs

output "name" {
  description = "Task name"
  value       = snowflake_task.this.name
}

output "fully_qualified_name" {
  description = "Fully qualified task name"
  value       = snowflake_task.this.fully_qualified_name
}

output "database" {
  description = "Database name"
  value       = snowflake_task.this.database
}

output "schema" {
  description = "Schema name"
  value       = snowflake_task.this.schema
}

output "started" {
  description = "Task started state"
  value       = snowflake_task.this.started
}
