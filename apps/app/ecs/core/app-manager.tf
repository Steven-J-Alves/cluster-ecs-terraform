# ------- ECS Task Definition -------
module "ecs_taks_definition_app_manager" {
  source = "../../../../modules/ecs_ec2/task_definition"
  name               = "${var.base_name}-manager-tf"
  network_mode       = "bridge"
  container_name     = var.container_name["app_manager"]
  execution_role_arn = var.ecs_role.arn_role
  task_role_arn      = var.ecs_role.arn_role_ecs_task_role
  cpu                = 256
  memory             = "512"
  docker_repo        = var.ecr_repositories.ecr_app_manager.ecr_repository_url
  region             = var.aws_region
  command = <<DEFINITION
    []
  DEFINITION
  environment        = <<DEFINITION
    [
    ]
  DEFINITION
}

# ------- ECS Service -------
module "ecs_service_app_manager" {
  source = "../../../../modules/ecs_ec2/service"
  name                = "${var.base_name}-manager"
  desired_tasks       = 1
  arn_security_group  = var.networking.security_group_ecs_task_app_manager.sg_id
  ecs_cluster_id      = var.cluster.ecs_cluster_id
  use_load_balancer   = false
  arn_task_definition = module.ecs_taks_definition_app_manager.arn_task_definition
  subnets_id          = var.data_private_subnets.ids
  container_name      = [var.container_name["app_manager"]]
}

# # ------- ECS Autoscaling Policies -------
module "ecs_autoscaling_app-manager" {
  depends_on    = [module.ecs_service_app_manager]
  source = "../../../../modules/ecs_ec2/autoscaling"
  name          = "${var.base_name}-manager"
  cluster_name  = var.cluster.ecs_cluster_name
  min_capacity  = 1
  max_capacity  = 3
  cpu_target    = 80
  memory_target = 80
}
