resource "aws_ecs_service" "ecs_service" {
  name            = var.name
  cluster         = var.ecs_cluster_id
  task_definition = var.arn_task_definition
  desired_count   = var.desired_tasks
  # health_check_grace_period_seconds = var.use_load_balancer ? null : 10
  launch_type = var.launch_type

  # network_configuration {
  #   security_groups = [var.arn_security_group]
  #   subnets         = [var.subnets_id[0], var.subnets_id[1]]
  # }

  dynamic "load_balancer" {
    for_each = var.use_load_balancer ? [1] : []
    content {
      target_group_arn = var.arn_target_group
      container_name   = var.container_name
      container_port   = var.container_port
    }
  }

  enable_execute_command = true

  lifecycle {
    ignore_changes = [desired_count, task_definition, load_balancer, deployment_maximum_percent, tags]
  }

}