# -- infra/snowflake/tf/modules/task/main.tf (Child Module)
# Creates Snowflake Task for scheduled data movement

resource "snowflake_task" "this" {
  name      = var.task.name
  database  = var.task.database
  schema    = var.task.schema
  warehouse = var.task.warehouse
  comment   = var.task.comment

  # Schedule block (required for standalone tasks)
  schedule {
    minutes = var.task.schedule_minutes
  }

  # Conditional execution - only run when stream has data
  when = var.task.when_condition

  sql_statement = var.task.sql_statement

  # Task state - started = true to enable
  started = var.task.started
}
