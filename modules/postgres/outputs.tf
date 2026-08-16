# output "rds_primary_endpoint" {
#   description = "Primary (writer) endpoint of the RDS PostgreSQL instance"
#   value       = aws_db_instance.primary_instance.endpoint
#   # value = replace(aws_db_instance.primary_instance.endpoint, ":5432", "")
# }
