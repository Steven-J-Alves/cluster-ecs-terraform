module "target_group_app_api_pvt" {
  source                           = "../../modules/alb"
  create_target_group              = true
  name                             = "${var.base_name}-api-pvt"
  port                             = "5096"
  protocol                         = "HTTP"
  vpc_id                           = var.data_vpc.id
  tg_type                          = "instance"
  health_check_path                = "/health"
  health_check_port                = var.port_api_app
  health_check_healthy_threshold   = 2
  health_check_unhealthy_threshold = 2
  health_check_timeout             = 3
  health_check_interval            = 5
  health_check_matcher             = "200-499"
}

module "target_group_app_front_pvt" {
  source                           = "../../modules/alb"
  create_target_group              = true
  name                             = "${var.base_name}-front-pvt"
  port                             = "5097"
  protocol                         = "HTTP"
  vpc_id                           = var.data_vpc.id
  tg_type                          = "instance"
  health_check_path                = "/health"
  health_check_port                = var.port_front_app
  health_check_healthy_threshold   = 2
  health_check_unhealthy_threshold = 2
  health_check_timeout             = 3
  health_check_interval            = 5
  health_check_matcher             = "200-399"
}

