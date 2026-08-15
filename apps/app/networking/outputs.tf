output "target_group_app_api_pvt" {
  value = module.target_group_app_api_pvt
}
output "target_group_app_front_pvt" {
  value = module.target_group_app_front_pvt
}

output "security_group_ecs_task_api" {
  value = module.security_group_ecs_task_app_api
}
output "security_group_ecs_task_app_worker" {
  value = module.security_group_ecs_task_app_worker
}
output "security_group_ecs_task_app_scheduler" {
  value = module.security_group_ecs_task_app_scheduler
}
output "security_group_ecs_task_app_manager" {
  value = module.security_group_ecs_task_app_manager
}
output "security_group_ecs_task_app_front" {
  value = module.security_group_ecs_task_app_front
}
