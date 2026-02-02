# -- infra/snowflake/tf/modules/task/variables.tf (Child Module)
# Snowflake Task Variables

variable "task" {
  description = "Task configuration"
  type = object({
    name             = string
    database         = string
    schema           = string
    warehouse        = string
    schedule_minutes = number
    sql_statement    = string
    comment          = optional(string, "")
    when_condition   = optional(string, null)
    started          = optional(bool, false)
  })
}
