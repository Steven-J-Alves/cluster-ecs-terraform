output "tfstate_bucket_name" {
  description = "Name of the S3 bucket used for Terraform remote state"
  value       = aws_s3_bucket.tfstate.bucket
}

output "network_lock_table_name" {
  description = "DynamoDB lock table name for the network stack"
  value       = aws_dynamodb_table.network_lock.name
}

output "cluster_lock_table_name" {
  description = "DynamoDB lock table name for the cluster stack"
  value       = aws_dynamodb_table.cluster_lock.name
}

output "apps_lock_table_name" {
  description = "DynamoDB lock table name for the apps stack"
  value       = aws_dynamodb_table.apps_lock.name
}

output "apps2_lock_table_name" {
  description = "DynamoDB lock table name for the apps2 stack"
  value       = aws_dynamodb_table.apps2_lock.name
}
