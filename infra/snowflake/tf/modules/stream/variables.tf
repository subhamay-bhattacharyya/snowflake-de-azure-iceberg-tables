# -- infra/snowflake/tf/modules/stream/variables.tf (Child Module)
# Snowflake Stream Variables

variable "stream" {
  description = "Stream configuration"
  type = object({
    name              = string
    database          = string
    schema            = string
    source_table      = string
    comment           = optional(string, "")
    append_only       = optional(bool, false)
    show_initial_rows = optional(bool, false)
  })
}
