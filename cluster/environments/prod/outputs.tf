output "service_discovery_namespace_id" {
  description = "The ID of the Service Discovery Private DNS Namespace"
  value       = module.prod_ecs_cluster_main.service_discovery_namespace_id
}

output "ecs_cluster" {
  value = module.prod_ecs_cluster_main.ecs_cluster
}

output "ecs_cluster_id" {
  value = module.prod_ecs_cluster_main.ecs_cluster_id
}

output "ecs_cluster_name" {
  value = module.prod_ecs_cluster_main.ecs_cluster_name
}

# Public
output "alb_public" {
  value = module.prod_ecs_cluster_main.alb_public
}

output "alb_arn_public" {
  value = module.prod_ecs_cluster_main.alb_arn_public
}

output "https_listener_arn_public" {
  value = module.prod_ecs_cluster_main.https_listener_arn_public
}

output "alb_dns_public" {
  value = module.prod_ecs_cluster_main.alb_dns_public
}

# Private
output "alb_private" {
  value = module.prod_ecs_cluster_main.alb_private
}

output "alb_arn_private" {
  value = module.prod_ecs_cluster_main.alb_arn_private
}

output "https_listener_arn_private" {
  value = module.prod_ecs_cluster_main.https_listener_arn_private
}

output "alb_dns_private" {
  value = module.prod_ecs_cluster_main.alb_dns_private
}