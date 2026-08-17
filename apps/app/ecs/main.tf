module "ecs_core_services" {
  source           = "./core"
  service_name     = var.service_name
  base_name        = var.base_name
  environment_name = var.environment_name
  aws_region       = var.aws_region

  cluster = data.terraform_remote_state.ecs_cluster_main.outputs

  networking           = var.networking
  data_private_subnets = var.data_private_subnets

  ecs_role        = var.ecs_role
  ecs_role_policy = var.ecs_role_policy

  container_name   = var.container_name
  ecr_repositories = var.ecr_repositories

  port_api_app   = var.port_api_app
  port_front_app = var.port_front_app
}
