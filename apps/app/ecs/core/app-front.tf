# ------- ECS Task Definition -------
module "ecs_taks_definition_app_front" {
  source             = "../../../modules/ecs_ec2/task_definition"
  name               = "${var.base_name}-front-tf"
  network_mode       = "bridge"
  container_name     = var.container_name["app_front"]
  execution_role_arn = var.ecs_role.arn_role
  task_role_arn      = var.ecs_role.arn_role_ecs_task_role
  cpu                = 256
  memory             = "512"
  docker_repo        = var.ecr_repositories.ecr_app_front.ecr_repository_url
  region             = var.aws_region
  container_port     = var.port_front_app
  command = <<DEFINITION
    []
  DEFINITION
  port_mappings      = <<DEFINITION
    [
        {
            "containerPort": ${var.port_front_app},
            "hostPort": 0
        }
    ]
  DEFINITION
  environment        = <<DEFINITION
    [
    ]
  DEFINITION
}

# ------- ECS Service -------
module "ecs_service_app_front" {
  source                            = "../../../modules/ecs_ec2/service"
  name                              = "${var.base_name}-front"
  desired_tasks                     = 1
  arn_security_group                = var.networking.security_group_ecs_task_app_front.sg_id
  ecs_cluster_id                    = var.cluster.ecs_cluster_id
  use_load_balancer                 = true
  arn_target_group                  = [var.networking.target_group_app_front_pvt.arn_tg]
  arn_task_definition               = module.ecs_taks_definition_app_front.arn_task_definition
  subnets_id                        = var.data_private_subnets.ids
  container_port                    = [var.port_front_app]
  container_name                    = [var.container_name["app_front"]]
  health_check_grace_period_seconds = 15
}

# # ------- ECS Autoscaling Policies -------
module "ecs_autoscaling_app-front" {
  depends_on    = [module.ecs_service_app_front]
  source        = "../../../modules/ecs_ec2/autoscaling"
  name          = "${var.base_name}-front"
  cluster_name  = var.cluster.ecs_cluster_name
  min_capacity  = 1
  max_capacity  = 3
  cpu_target    = 80
  memory_target = 80
}
