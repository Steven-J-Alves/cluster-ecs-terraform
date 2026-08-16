# ------- Service app-api - Security Group -------
module "security_group_ecs_task_app_api" {
  source = "../../../modules/securitygroup"
  name                = "${var.base_name}-api-task-sg"
  description         = "Controls access to the app-api ECS task"  
  vpc_id              = var.data_vpc.id
  ingress_port        = var.port_api_app
  cidr_blocks_ingress = [var.data_vpc.cidr_block, var.kriolu_kloud_vpn]
}

# ------- Service app-worker - Security Group -------
module "security_group_ecs_task_app_worker" {
  source = "../../../modules/securitygroup"
  name                = "${var.base_name}-worker-task-sg"
  description         = "Controls access to the app-worker ECS task" 
  vpc_id              = var.data_vpc.id
  cidr_blocks_ingress = [var.data_vpc.cidr_block, var.kriolu_kloud_vpn]
}

module "security_group_ecs_task_app_scheduler" {
  source = "../../../modules/securitygroup"
  name                = "${var.base_name}-scheduler-task-sg"
  description         = "Controls access to the app-scheduler ECS task"
  vpc_id              = var.data_vpc.id
  cidr_blocks_ingress = [var.data_vpc.cidr_block, var.kriolu_kloud_vpn]
}

module "security_group_ecs_task_app_manager" {
  source = "../../../modules/securitygroup"
  name                = "${var.base_name}-manager-task-sg"
  description         = "Controls access to the app-manager ECS task"
  vpc_id              = var.data_vpc.id
  cidr_blocks_ingress = [var.data_vpc.cidr_block, var.kriolu_kloud_vpn]
}

module "security_group_ecs_task_app_front" {
  source = "../../../modules/securitygroup"
  name                = "${var.base_name}-front-task-sg"
  description         = "Controls access to the app-front ECS task"
  vpc_id              = var.data_vpc.id
  ingress_port        = var.port_front_app
  cidr_blocks_ingress = [var.data_vpc.cidr_block, var.kriolu_kloud_vpn]
}
