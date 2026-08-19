output "rds_endpoint" {
  value     = module.prod_app2.rds_endpoint
  sensitive = false
}

output "rds_port" {
  value = module.prod_app2.rds_port
}
