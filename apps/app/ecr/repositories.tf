module "ecr_app_api" {
  source = "../../modules/ecr"
  name   = "${var.base_name}-api"
}

module "ecr_app_worker" {
  source = "../../modules/ecr"
  name   = "${var.base_name}-worker"
}

module "ecr_app_scheduler" {
  source = "../../modules/ecr"
  name   = "${var.base_name}-scheduler"
}

module "ecr_app_manager" {
  source = "../../modules/ecr"
  name   = "${var.base_name}-manager"
}

module "ecr_app_front" {
  source = "../../modules/ecr"
  name   = "${var.base_name}-front"
}
