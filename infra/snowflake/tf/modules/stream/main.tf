# -- infra/snowflake/tf/modules/stream/main.tf (Child Module)
# Creates Snowflake Stream on a table

resource "snowflake_stream_on_table" "this" {
  name     = var.stream.name
  database = var.stream.database
  schema   = var.stream.schema
  comment  = var.stream.comment

  # Fully qualified table name
  table = "${var.stream.database}.${var.stream.schema}.${var.stream.source_table}"

  # Append only mode - "true" or "false" as string
  append_only = var.stream.append_only ? "true" : "false"
}
