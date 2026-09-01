module "ecs_role" {
  source = "../../modules/iam"

  create_ecs_role    = true
  name               = "${local.workload_name}-execution-role"
  name_ecs_task_role = "${local.workload_name}-task-role"
}

module "ecs_role_policy" {
  source = "../../modules/iam"

  name          = "${local.workload_name}-ecr-policy"
  create_policy = true
  attach_to     = module.ecs_role.name_role
}
